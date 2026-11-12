import Darwin
import Foundation

public actor GitRepositoryService {
    private let executableURL: URL
    private let previewLimit = 256 * 1_024

    public init(executableURL: URL = URL(fileURLWithPath: "/usr/bin/git")) {
        self.executableURL = executableURL
    }

    public func inspect(folder: URL) async throws -> RepositorySnapshot {
        var isDirectory: ObjCBool = false
        guard folder.isFileURL,
              FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw GitRepositoryError.directoryUnavailable
        }
        let rootData = try await command(in: folder, arguments: ["rev-parse", "--show-toplevel"])
        let root = try directoryURL(from: rootData)
        let filterOverrides = try await disabledFilters(in: root)
        async let gitDirectory = command(in: root, arguments: ["rev-parse", "--absolute-git-dir"])
        async let commonDirectory = command(in: root, arguments: ["rev-parse", "--path-format=absolute", "--git-common-dir"])
        async let statusOutput = command(in: root, arguments: ["status", "--porcelain=v2", "-z", "--branch", "--ahead-behind",
                                                              "--untracked-files=all", "--ignore-submodules=all"], configuration: filterOverrides)
        async let remoteOutput = command(in: root, arguments: ["config", "--null", "--get-regexp", #"^remote\..*\.(url|pushurl)$"#], allowedExitCodes: [0, 1])
        let (gitData, commonData, statusData, remotesData) = try await (gitDirectory, commonDirectory, statusOutput, remoteOutput)
        let status = try GitOutputParser.status(statusData)
        return RepositorySnapshot(rootURL: root, gitDirectoryURL: try directoryURL(from: gitData),
                                  commonDirectoryURL: try directoryURL(from: commonData),
                                  branch: status.branch, headSHA: status.headSHA, upstream: status.upstream,
                                  ahead: status.ahead, behind: status.behind, changes: status.changes,
                                  remotes: try GitOutputParser.remotes(remotesData), inspectedAt: Date(),
                                  filtersDisabled: !filterOverrides.isEmpty)
    }

    public func diff(in repository: URL, change: FileChange, staged: Bool) async throws -> String {
        try validate(path: change.path)
        if let original = change.originalPath { try validate(path: original) }
        if change.isUntracked {
            return staged ? "This file has not been staged." : try previewUntracked(in: repository, path: change.path)
        }
        var arguments = ["diff", "--no-ext-diff", "--no-textconv", "--no-color", "--ignore-submodules=all", "--src-prefix=a/", "--dst-prefix=b/"]
        if staged { arguments.append("--cached") }
        arguments.append("--")
        if let original = change.originalPath { arguments.append(original) }
        arguments.append(change.path)
        let filterOverrides = try await disabledFilters(in: repository)
        let data = try await command(in: repository, arguments: arguments, configuration: filterOverrides)
        guard let value = String(data: data, encoding: .utf8) else {
            return "This diff contains non-UTF-8 data and cannot be displayed as text."
        }
        return value.isEmpty ? "No changes in this view." : value
    }

    private func disabledFilters(in folder: URL) async throws -> [String] {
        let data = try await command(in: folder, arguments: ["config", "--null", "--name-only", "--get-regexp",
                                                            #"^filter\..*\.(clean|smudge|process|required)$"#], allowedExitCodes: [0, 1])
        var drivers = Set<String>()
        for bytes in data.split(separator: 0) {
            guard let key = String(bytes: bytes, encoding: .utf8), let separator = key.lastIndex(of: ".") else {
                throw GitRepositoryError.invalidOutput
            }
            drivers.insert(String(key[..<separator]))
        }
        // Status and diff can run clean/process filters even when external diff is disabled.
        return drivers.sorted().flatMap { driver in
            ["-c", "\(driver).clean=", "-c", "\(driver).smudge=", "-c", "\(driver).process=", "-c", "\(driver).required=false"]
        }
    }

    private func command(in folder: URL, arguments: [String], allowedExitCodes: Set<Int32> = [0], configuration: [String] = []) async throws -> Data {
        let safeArguments = ["--no-pager", "--literal-pathspecs", "--no-optional-locks",
                             "-c", "core.fsmonitor=false", "-c", "core.hooksPath=/dev/null",
                             "-c", "diff.external=", "-c", "core.quotePath=false", "-C", folder.path] + configuration + arguments
        let result = try await GitProcess().run(executable: executableURL, arguments: safeArguments)
        guard allowedExitCodes.contains(result.exitCode) else {
            let error = String(decoding: result.error, as: UTF8.self)
            if error.contains("not a git repository") { throw GitRepositoryError.notRepository }
            let safeError = GitOutputParser.redact(error).trimmingCharacters(in: .whitespacesAndNewlines)
            throw GitRepositoryError.commandFailed(String(safeError.prefix(1_000)))
        }
        return result.output
    }

    private func directoryURL(from data: Data) throws -> URL {
        guard var path = String(data: data, encoding: .utf8), path.hasSuffix("\n") else {
            throw GitRepositoryError.invalidOutput
        }
        path.removeLast()
        guard path.hasPrefix("/") else { throw GitRepositoryError.invalidOutput }
        return URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
    }

    private func validate(path: String) throws {
        guard !path.isEmpty, !path.hasPrefix("/"), !path.contains("\0"),
              !path.split(separator: "/", omittingEmptySubsequences: false).contains(where: { $0 == ".." || $0 == "." || $0.isEmpty }) else {
            throw GitRepositoryError.unsafePath
        }
    }

    private func previewUntracked(in repository: URL, path: String) throws -> String {
        let root = repository.resolvingSymlinksInPath().standardizedFileURL
        var descriptor = open(root.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW)
        guard descriptor >= 0 else { throw GitRepositoryError.directoryUnavailable }
        defer { close(descriptor) }
        let components = path.split(separator: "/").map(String.init)
        for (index, component) in components.enumerated() {
            let isLast = index == components.count - 1
            // openat with O_NOFOLLOW prevents both traversal through links and a link swap during preview.
            let next = openat(descriptor, component, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | (isLast ? 0 : O_DIRECTORY))
            guard next >= 0 else { throw GitRepositoryError.unsafePath }
            close(descriptor)
            descriptor = next
        }
        var metadata = stat()
        guard fstat(descriptor, &metadata) == 0, metadata.st_mode & S_IFMT == S_IFREG else {
            throw GitRepositoryError.unsafePath
        }
        guard metadata.st_size <= previewLimit else { return "This untracked file is larger than 256 KB. Open it in your editor to inspect it." }
        var bytes = [UInt8](repeating: 0, count: previewLimit + 1)
        var count = 0
        while count < bytes.count {
            let readCount = bytes.withUnsafeMutableBytes { buffer in
                Darwin.read(descriptor, buffer.baseAddress!.advanced(by: count), buffer.count - count)
            }
            if readCount == 0 { break }
            guard readCount > 0 else { throw GitRepositoryError.unsafePath }
            count += readCount
        }
        guard count <= previewLimit else { return "This untracked file is larger than 256 KB. Open it in your editor to inspect it." }
        let data = Data(bytes.prefix(count))
        guard !data.contains(0), let text = String(data: data, encoding: .utf8) else {
            return "This untracked file is binary or uses an unsupported text encoding."
        }
        return text.isEmpty ? "This untracked file is empty." : text
    }
}
