import Foundation
import Testing
@testable import GitEngine

@Test func inspectsStagedUnstagedAndUntrackedChangesFromSubfolder() async throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }
    try fixture.write("tracked.txt", "initial\n")
    try fixture.commitAll()
    try fixture.write("tracked.txt", "staged\n")
    try fixture.git(["add", "tracked.txt"])
    try fixture.write("tracked.txt", "unstaged\n")
    try fixture.write("nested/new file.txt", "new content\n")
    let service = GitRepositoryService()

    let snapshot = try await service.inspect(folder: fixture.url.appendingPathComponent("nested"))

    #expect(snapshot.rootURL.standardizedFileURL.path == fixture.url.standardizedFileURL.path)
    #expect(snapshot.branch == "main")
    #expect(snapshot.headSHA?.count == 40)
    #expect(snapshot.remotes.isEmpty)
    let tracked = try #require(snapshot.changes.first { $0.path == "tracked.txt" })
    #expect(tracked.indexStatus == "M")
    #expect(tracked.worktreeStatus == "M")
    #expect(tracked.hasStagedChanges && tracked.hasUnstagedChanges)
    #expect(try await service.diff(in: snapshot.rootURL, change: tracked, staged: true).contains("+staged"))
    #expect(try await service.diff(in: snapshot.rootURL, change: tracked, staged: false).contains("+unstaged"))
    let untracked = try #require(snapshot.changes.first { $0.isUntracked })
    #expect(untracked.path == "nested/new file.txt")
    #expect(!untracked.hasStagedChanges)
    #expect(try await service.diff(in: snapshot.rootURL, change: untracked, staged: false) == "new content\n")
}

@Test func preservesRenamePathsWithSpacesTabsAndNewlines() async throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }
    let original = "old name\twith\nnewline.txt"
    let renamed = "new name\twith\nnewline.txt"
    try fixture.write(original, "unchanged content\n")
    try fixture.commitAll()
    try fixture.git(["mv", "--", original, renamed])
    let service = GitRepositoryService()

    let snapshot = try await service.inspect(folder: fixture.url)

    let change = try #require(snapshot.changes.first)
    #expect(snapshot.changes.count == 1)
    #expect(change.path == renamed)
    #expect(change.originalPath == original)
    #expect(change.indexStatus == "R")
    #expect(try await service.diff(in: fixture.url, change: change, staged: true).contains("similarity index 100%"))
}

@Test func handlesUnbornAndDetachedHead() async throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }
    let service = GitRepositoryService()
    let unborn = try await service.inspect(folder: fixture.url)
    #expect(unborn.branch == "main")
    #expect(unborn.headSHA == nil)
    try fixture.write("first.txt", "first\n")
    try fixture.git(["add", "."])
    let staged = try await service.inspect(folder: fixture.url)
    #expect(try await service.diff(in: fixture.url, change: #require(staged.changes.first), staged: true).contains("+first"))
    try fixture.commitAll()
    try fixture.git(["checkout", "--detach", "HEAD"])
    let detached = try await service.inspect(folder: fixture.url)
    #expect(detached.branch == nil)
    #expect(detached.headSHA?.count == 40)
}

@Test func identifiesLinkedWorktreeAndNewlineInRootPath() async throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }
    try fixture.write("first.txt", "first\n")
    try fixture.commitAll()
    let worktree = fixture.container.appendingPathComponent("linked worktree\nsecond")
    try fixture.git(["worktree", "add", "-b", "feature", worktree.path])
    let snapshot = try await GitRepositoryService().inspect(folder: worktree)
    #expect(snapshot.rootURL.path == worktree.path)
    #expect(snapshot.branch == "feature")
    #expect(snapshot.gitDirectoryURL != snapshot.commonDirectoryURL)
    #expect(snapshot.commonDirectoryURL.path == fixture.url.appendingPathComponent(".git").path)
}

@Test func reportsPlainAndMissingFoldersClearly() async throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }
    let service = GitRepositoryService()
    await #expect(throws: GitRepositoryError.notRepository) {
        try await service.inspect(folder: fixture.container)
    }
    await #expect(throws: GitRepositoryError.directoryUnavailable) {
        try await service.inspect(folder: fixture.container.appendingPathComponent("missing"))
    }
}

@Test func redactsRemoteCredentialsAndMatchesOnlyGitHub() async throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }
    try fixture.git(["remote", "add", "origin", "https://my-user:super-secret@github.com/owner/repo.git?token=secret#fragment"])
    try fixture.git(["remote", "set-url", "--push", "origin", "ssh://secret-user:password@github.com/owner/repo.git"])
    try fixture.git(["remote", "add", "lookalike", "https://github.com.attacker.example/owner/repo.git"])
    try fixture.git(["remote", "add", "ssh", "git@github.com:other/repository.git"])
    let snapshot = try await GitRepositoryService().inspect(folder: fixture.url)
    let origin = try #require(snapshot.remotes.first { $0.name == "origin" })
    #expect(origin.githubURL?.absoluteString == "https://github.com/owner/repo")
    #expect(origin.fetchURL == "https://[redacted]@github.com/owner/repo.git")
    #expect(origin.pushURL == "ssh://[redacted]@github.com/owner/repo.git")
    #expect(snapshot.remotes.first { $0.name == "lookalike" }?.githubURL == nil)
    #expect(snapshot.remotes.first { $0.name == "ssh" }?.githubURL?.absoluteString == "https://github.com/other/repository")
    #expect(GitOutputParser.redact("fatal: https://name:token@github.com/a/b?access_token=hidden") == "fatal: https://[redacted]@github.com/a/b")
}

@Test func neverRunsConfiguredStatusOrDiffHelpers() async throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }
    try fixture.write("tracked.txt", "initial\n")
    try fixture.write(".gitattributes", "*.txt diff=custom\n")
    try fixture.commitAll()
    try fixture.write("tracked.txt", "changed\n")
    let marker = fixture.container.appendingPathComponent("helper-was-run")
    let helper = fixture.container.appendingPathComponent("helper.sh")
    try "#!/bin/sh\n/usr/bin/touch \"\(marker.path)\"\nexit 1\n".write(to: helper, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: helper.path)
    try fixture.git(["config", "core.fsmonitor", helper.path])
    try fixture.git(["config", "diff.external", helper.path])
    try fixture.git(["config", "diff.custom.textconv", helper.path])
    try fixture.git(["config", "diff.custom.command", helper.path])
    let service = GitRepositoryService()
    let snapshot = try await service.inspect(folder: fixture.url)
    let change = try #require(snapshot.changes.first { $0.path == "tracked.txt" })
    #expect(try await service.diff(in: fixture.url, change: change, staged: false).contains("+changed"))
    #expect(!FileManager.default.fileExists(atPath: marker.path))
}

@Test func limitsUntrackedPreviewsAndRejectsLinksOrTraversal() async throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }
    try fixture.write("large.txt", String(repeating: "a", count: 300_000))
    try Data([0, 1, 2, 3]).write(to: fixture.url.appendingPathComponent("binary.dat"))
    let outside = fixture.container.appendingPathComponent("private.txt")
    try "private content".write(to: outside, atomically: true, encoding: .utf8)
    try FileManager.default.createSymbolicLink(at: fixture.url.appendingPathComponent("link"), withDestinationURL: outside)
    try FileManager.default.createSymbolicLink(at: fixture.url.appendingPathComponent("outside"), withDestinationURL: fixture.container)
    let service = GitRepositoryService()
    func untracked(_ path: String) -> FileChange {
        FileChange(path: path, indexStatus: ".", worktreeStatus: "?", isUntracked: true)
    }
    #expect(try await service.diff(in: fixture.url, change: untracked("large.txt"), staged: false).contains("larger than 256 KB"))
    #expect(try await service.diff(in: fixture.url, change: untracked("binary.dat"), staged: false).contains("binary"))
    for path in ["link", "outside/private.txt", "../private.txt", "/etc/passwd"] {
        await #expect(throws: GitRepositoryError.unsafePath) {
            try await service.diff(in: fixture.url, change: untracked(path), staged: false)
        }
    }
}

@Test func neverRunsConfiguredCleanFiltersDuringInspection() async throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }
    try fixture.write("tracked.txt", "initial\n")
    try fixture.write(".gitattributes", "*.txt filter=custom\n")
    try fixture.commitAll()
    let marker = fixture.container.appendingPathComponent("filter-was-run")
    let helper = fixture.container.appendingPathComponent("filter.sh")
    try "#!/bin/sh\n/usr/bin/touch \"\(marker.path)\"\n/bin/cat\n".write(to: helper, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: helper.path)
    try fixture.git(["config", "filter.custom.clean", helper.path])
    try fixture.git(["config", "filter.custom.process", helper.path])
    try fixture.git(["config", "filter.custom.required", "true"])
    try fixture.write("tracked.txt", "changed\n")
    let service = GitRepositoryService()
    let snapshot = try await service.inspect(folder: fixture.url)
    #expect(snapshot.filtersDisabled)
    let change = try #require(snapshot.changes.first { $0.path == "tracked.txt" })
    _ = try await service.diff(in: fixture.url, change: change, staged: false)
    #expect(!FileManager.default.fileExists(atPath: marker.path))
}

@Test func reportsUpstreamDivergenceWithoutFetching() async throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }
    let bare = fixture.container.appendingPathComponent("remote.git")
    try fixture.git(["init", "--bare", bare.path])
    try fixture.write("tracked.txt", "initial\n")
    try fixture.commitAll()
    try fixture.git(["remote", "add", "origin", bare.path])
    try fixture.git(["push", "-u", "origin", "main"])
    try fixture.write("tracked.txt", "ahead\n")
    try fixture.commitAll()
    let snapshot = try await GitRepositoryService().inspect(folder: fixture.url)
    #expect(snapshot.upstream == "origin/main")
    #expect(snapshot.ahead == 1)
    #expect(snapshot.behind == 0)
}

@Test func identifiesMergeConflicts() async throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }
    try fixture.write("conflict.txt", "base\n")
    try fixture.commitAll()
    try fixture.git(["checkout", "-b", "other"])
    try fixture.write("conflict.txt", "theirs\n")
    try fixture.commitAll()
    try fixture.git(["checkout", "main"])
    try fixture.write("conflict.txt", "ours\n")
    try fixture.commitAll()
    try fixture.git(["merge", "other"], allowedExitCodes: [1])
    let snapshot = try await GitRepositoryService().inspect(folder: fixture.url)
    let conflict = try #require(snapshot.changes.first)
    #expect(conflict.isConflicted)
    #expect(conflict.indexStatus == "U")
    #expect(conflict.worktreeStatus == "U")
}

@Test func cancelsAnUnresponsiveGitProcess() async throws {
    let fixture = try RepositoryFixture()
    defer { fixture.remove() }
    let executable = fixture.container.appendingPathComponent("slow-git.sh")
    try "#!/bin/sh\nexec /bin/sleep 30\n".write(to: executable, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
    let service = GitRepositoryService(executableURL: executable)
    let task = Task { try await service.inspect(folder: fixture.url) }
    try await Task.sleep(for: .milliseconds(100))
    task.cancel()
    await #expect(throws: CancellationError.self) { try await task.value }
}

private struct RepositoryFixture: Sendable {
    let container: URL
    let url: URL

    init() throws {
        container = FileManager.default.temporaryDirectory.appendingPathComponent("GitEngineTests-\(UUID().uuidString)", isDirectory: true)
        url = container.appendingPathComponent("repository", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try git(["init", "-b", "main"])
        try git(["config", "user.name", "Git Engine Tests"])
        try git(["config", "user.email", "git-engine-tests@example.invalid"])
        try git(["config", "commit.gpgSign", "false"])
    }

    func write(_ path: String, _ text: String) throws {
        let target = url.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: target, atomically: true, encoding: .utf8)
    }

    func commitAll() throws {
        try git(["add", "--all"])
        try git(["commit", "-m", "Fixture commit"])
    }

    func git(_ arguments: [String], allowedExitCodes: Set<Int32> = [0]) throws {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-c", "core.hooksPath=/dev/null", "-C", url.path] + arguments
        process.environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
            .merging(["GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_TERMINAL_PROMPT": "0"], uniquingKeysWith: { _, new in new })
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard allowedExitCodes.contains(process.terminationStatus) else {
            throw FixtureError.failed(String(decoding: output, as: UTF8.self))
        }
    }

    func remove() { try? FileManager.default.removeItem(at: container) }
}

private enum FixtureError: Error {
    case failed(String)
}
