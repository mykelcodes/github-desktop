import Foundation

public struct ConnectedFolder: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let path: String
    public let connectedAt: Date

    public var url: URL { URL(fileURLWithPath: path, isDirectory: true) }
    public var name: String { url.lastPathComponent }

    public init(id: UUID = UUID(), path: String, connectedAt: Date = Date()) {
        self.id = id
        self.path = path
        self.connectedAt = connectedAt
    }
}

public actor FolderRegistry {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func folders() throws -> [ConnectedFolder] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        return try JSONDecoder().decode([ConnectedFolder].self, from: Data(contentsOf: fileURL))
    }

    @discardableResult
    public func connect(rootURL: URL) throws -> ConnectedFolder {
        let path = rootURL.resolvingSymlinksInPath().standardizedFileURL.path
        var saved = try folders()
        if let existing = saved.first(where: { $0.path == path }) { return existing }
        let folder = ConnectedFolder(path: path)
        saved.append(folder)
        try save(saved)
        return folder
    }

    public func disconnect(id: UUID) throws {
        try save(folders().filter { $0.id != id })
    }

    private func save(_ folders: [ConnectedFolder]) throws {
        let manager = FileManager.default
        try manager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(folders).write(to: fileURL, options: .atomic)
        try manager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }
}
