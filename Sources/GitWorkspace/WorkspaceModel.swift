import AppKit
import Foundation
import GitEngine
import Observation
import WorkspaceCore

@MainActor
@Observable
final class WorkspaceModel {
    var folders: [ConnectedFolder] = []
    var selectedID: UUID?
    var snapshot: RepositorySnapshot?
    var isLoading = false
    var isConnecting = false
    var connectionError: String?
    var repositoryError: String?

    let git = GitRepositoryService()
    private let registry: FolderRegistry
    private var refreshTask: Task<Void, Never>?
    private var refreshID = UUID()
    private var didStart = false

    var selectedFolder: ConnectedFolder? { folders.first { $0.id == selectedID } }

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let storage: URL
        if let index = arguments.firstIndex(of: "--registry-path"), arguments.indices.contains(index + 1) {
            storage = URL(fileURLWithPath: arguments[index + 1])
        } else {
            storage = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("GitWorkspace/folders.json")
        }
        registry = FolderRegistry(fileURL: storage)
    }

    func start() async {
        guard !didStart else { return }
        didStart = true
        do {
            folders = try await registry.folders()
            let arguments = ProcessInfo.processInfo.arguments
            if let index = arguments.firstIndex(of: "--repository"), arguments.indices.contains(index + 1) {
                await connect(URL(fileURLWithPath: arguments[index + 1], isDirectory: true))
            } else if let first = folders.first {
                select(first.id)
            }
        } catch {
            connectionError = "Saved folders could not be loaded. Your repository files have not changed.\n\n\(error.localizedDescription)"
        }
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = "Connect a local repository"
        panel.message = "Choose an existing Git repository, or a folder inside it."
        panel.prompt = "Connect Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in await self?.connect(url) }
        }
    }

    func connect(_ url: URL) async {
        guard !isConnecting else { return }
        isConnecting = true
        defer { isConnecting = false }
        do {
            let inspected = try await git.inspect(folder: url)
            let folder = try await registry.connect(rootURL: inspected.rootURL)
            folders = try await registry.folders()
            refreshTask?.cancel()
            refreshID = UUID()
            selectedID = folder.id
            snapshot = inspected
            repositoryError = nil
            isLoading = false
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func select(_ id: UUID?) {
        guard selectedID != id else { return }
        selectedID = id
        snapshot = nil
        repositoryError = nil
        refresh()
    }

    func refresh() {
        refreshTask?.cancel()
        let requestID = UUID()
        refreshID = requestID
        guard let folder = selectedFolder else {
            snapshot = nil
            isLoading = false
            return
        }
        isLoading = true
        refreshTask = Task {
            do {
                let result = try await git.inspect(folder: folder.url)
                guard !Task.isCancelled, refreshID == requestID else { return }
                snapshot = result
                repositoryError = nil
                isLoading = false
            } catch {
                guard !Task.isCancelled, refreshID == requestID else { return }
                snapshot = nil
                repositoryError = error.localizedDescription
                isLoading = false
            }
        }
    }

    func disconnect(_ folder: ConnectedFolder) async {
        do {
            try await registry.disconnect(id: folder.id)
            folders = try await registry.folders()
            if selectedID == folder.id { select(folders.first?.id) }
        } catch {
            connectionError = "The folder could not be disconnected.\n\n\(error.localizedDescription)"
        }
    }

    func reveal(_ url: URL) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    }
}
