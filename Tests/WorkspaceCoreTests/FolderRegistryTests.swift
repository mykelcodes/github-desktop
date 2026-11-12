import Foundation
import Testing
@testable import WorkspaceCore

struct FolderRegistryTests {
    @Test func persistsFoldersAndDeduplicatesCanonicalPaths() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = directory.appendingPathComponent("Project with spaces")
        try FileManager.default.createDirectory(at: repository, withIntermediateDirectories: true)
        let alias = directory.appendingPathComponent("alias")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: repository)
        let file = directory.appendingPathComponent("state/folders.json")
        let registry = FolderRegistry(fileURL: file)

        #expect(try await registry.folders().isEmpty)
        let connected = try await registry.connect(rootURL: repository)
        let duplicate = try await registry.connect(rootURL: alias)
        #expect(connected.id == duplicate.id)
        let reopened = FolderRegistry(fileURL: file)
        #expect(try await reopened.folders() == [connected])
        let permissions = try FileManager.default.attributesOfItem(atPath: file.path)[.posixPermissions] as? Int
        #expect(permissions == 0o600)
    }

    @Test func disconnectPreservesFolderAndContents() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("source.txt")
        try Data("keep this work".utf8).write(to: source)
        let registry = FolderRegistry(fileURL: directory.appendingPathComponent("state/folders.json"))
        let folder = try await registry.connect(rootURL: directory)
        try await registry.disconnect(id: folder.id)
        #expect(try await registry.folders().isEmpty)
        #expect(try String(contentsOf: source, encoding: .utf8) == "keep this work")
    }

    @Test func corruptRegistryIsNotSilentlyReplaced() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("folders.json")
        let damaged = Data("invalid registry".utf8)
        try damaged.write(to: file)
        let registry = FolderRegistry(fileURL: file)
        await #expect(throws: (any Error).self) { try await registry.connect(rootURL: directory) }
        #expect(try Data(contentsOf: file) == damaged)
    }
}
