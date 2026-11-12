import Foundation

public struct RepositorySnapshot: Hashable, Sendable {
    public let rootURL: URL
    public let gitDirectoryURL: URL
    public let commonDirectoryURL: URL
    public let branch: String?
    public let headSHA: String?
    public let upstream: String?
    public let ahead: Int
    public let behind: Int
    public let changes: [FileChange]
    public let remotes: [GitRemote]
    public let inspectedAt: Date
    public let filtersDisabled: Bool

    public init(rootURL: URL, gitDirectoryURL: URL, commonDirectoryURL: URL,
                branch: String?, headSHA: String?, upstream: String?, ahead: Int,
                behind: Int, changes: [FileChange], remotes: [GitRemote], inspectedAt: Date, filtersDisabled: Bool = false) {
        self.rootURL = rootURL
        self.gitDirectoryURL = gitDirectoryURL
        self.commonDirectoryURL = commonDirectoryURL
        self.branch = branch
        self.headSHA = headSHA
        self.upstream = upstream
        self.ahead = ahead
        self.behind = behind
        self.changes = changes
        self.remotes = remotes
        self.inspectedAt = inspectedAt
        self.filtersDisabled = filtersDisabled
    }
}

public struct FileChange: Identifiable, Hashable, Sendable {
    public var id: String { path }
    public let path: String
    public let originalPath: String?
    public let indexStatus: String
    public let worktreeStatus: String
    public let isUntracked: Bool
    public let isConflicted: Bool

    public var hasStagedChanges: Bool { !isUntracked && indexStatus != "." }
    public var hasUnstagedChanges: Bool { isUntracked || worktreeStatus != "." }

    public init(path: String, originalPath: String? = nil, indexStatus: String,
                worktreeStatus: String, isUntracked: Bool = false, isConflicted: Bool = false) {
        self.path = path
        self.originalPath = originalPath
        self.indexStatus = indexStatus
        self.worktreeStatus = worktreeStatus
        self.isUntracked = isUntracked
        self.isConflicted = isConflicted
    }
}

public struct GitRemote: Identifiable, Hashable, Sendable {
    public var id: String { name }
    public let name: String
    public let fetchURL: String?
    public let pushURL: String?
    public let githubURL: URL?

    public init(name: String, fetchURL: String?, pushURL: String?, githubURL: URL?) {
        self.name = name
        self.fetchURL = fetchURL
        self.pushURL = pushURL
        self.githubURL = githubURL
    }
}

public enum GitRepositoryError: LocalizedError, Equatable, Sendable {
    case notRepository
    case directoryUnavailable
    case gitUnavailable
    case commandFailed(String)
    case outputLimit
    case timedOut
    case invalidOutput
    case unsafePath

    public var errorDescription: String? {
        switch self {
        case .notRepository: "This folder is not inside a Git repository. Choose an existing checkout."
        case .directoryUnavailable: "The selected folder is unavailable. Locate it and try again."
        case .gitUnavailable: "Git could not be started. Install the Xcode Command Line Tools and try again."
        case .commandFailed(let message): "Git could not inspect this repository. \(message)"
        case .outputLimit: "This operation produced too much data to display. Try a smaller repository or file."
        case .timedOut: "Git took too long to respond. Try again after other Git operations finish."
        case .invalidOutput: "Git returned data that could not be read, including a potentially unsupported filename."
        case .unsafePath: "This file cannot be previewed safely inside the selected repository."
        }
    }
}
