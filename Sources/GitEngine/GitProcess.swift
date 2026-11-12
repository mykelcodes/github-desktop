import Darwin
import Foundation

struct GitCommandResult: Sendable {
    let output: Data
    let error: Data
    let exitCode: Int32
}

final class GitProcess: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?
    private var interruption: Interruption?
    private let outputLimit = 8 * 1_024 * 1_024
    private let timeout: TimeInterval = 20

    private enum Interruption {
        case cancelled, timedOut, outputLimit
    }

    func run(executable: URL, arguments: [String]) async throws -> GitCommandResult {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        continuation.resume(returning: try self.runBlocking(executable: executable, arguments: arguments))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } onCancel: {
            self.interrupt(.cancelled)
        }
    }

    private func runBlocking(executable: URL, arguments: [String]) throws -> GitCommandResult {
        let child = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        child.executableURL = executable
        child.arguments = arguments
        child.standardOutput = outputPipe
        child.standardError = errorPipe
        child.standardInput = FileHandle.nullDevice
        var environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
        environment["GIT_OPTIONAL_LOCKS"] = "0"
        environment["GIT_TERMINAL_PROMPT"] = "0"
        environment["LC_ALL"] = "C"
        child.environment = environment

        lock.lock()
        if interruption != nil {
            lock.unlock()
            throw CancellationError()
        }
        do {
            try child.run()
            process = child
            lock.unlock()
        } catch {
            lock.unlock()
            throw GitRepositoryError.gitUnavailable
        }

        let output = BoundedData(limit: outputLimit)
        let error = BoundedData(limit: outputLimit)
        let readers = DispatchGroup()
        read(outputPipe.fileHandleForReading, into: output, group: readers)
        read(errorPipe.fileHandleForReading, into: error, group: readers)
        let deadline = DispatchWorkItem { [weak self] in self?.interrupt(.timedOut) }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: deadline)
        child.waitUntilExit()
        deadline.cancel()
        readers.wait()
        lock.lock()
        process = nil
        let reason = interruption
        lock.unlock()
        switch reason {
        case .cancelled: throw CancellationError()
        case .timedOut: throw GitRepositoryError.timedOut
        case .outputLimit: throw GitRepositoryError.outputLimit
        case nil: return GitCommandResult(output: output.data, error: error.data, exitCode: child.terminationStatus)
        }
    }

    private func read(_ handle: FileHandle, into buffer: BoundedData, group: DispatchGroup) {
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            defer {
                try? handle.close()
                group.leave()
            }
            while let chunk = try? handle.read(upToCount: 64 * 1_024), !chunk.isEmpty {
                if !buffer.append(chunk) { self.interrupt(.outputLimit) }
            }
        }
    }

    private func interrupt(_ reason: Interruption) {
        lock.lock()
        defer { lock.unlock() }
        guard interruption == nil else { return }
        interruption = reason
        if let process, process.isRunning {
            // A hard stop also bounds unresponsive local helpers; these commands never write Git state.
            kill(process.processIdentifier, SIGKILL)
        }
    }
}

private final class BoundedData: @unchecked Sendable {
    private let lock = NSLock()
    private let limit: Int
    private var storage = Data()

    init(limit: Int) { self.limit = limit }

    var data: Data { lock.withLock { storage } }

    func append(_ data: Data) -> Bool {
        lock.withLock {
            guard storage.count + data.count <= limit else { return false }
            storage.append(data)
            return true
        }
    }
}
