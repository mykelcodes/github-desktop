import AppKit
import SwiftUI

@main
struct GitWorkspaceApp: App {
    @State private var workspace = WorkspaceModel()

    var body: some Scene {
        WindowGroup("Git Workspace") {
            WorkspaceView(workspace: workspace)
                .frame(minWidth: 940, minHeight: 620)
                .task { await workspace.start() }
        }
        .defaultSize(width: 1220, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Connect Folder…", action: workspace.chooseFolder)
                    .keyboardShortcut("o", modifiers: .command)
                    .disabled(workspace.isConnecting)
            }
            CommandGroup(after: .toolbar) {
                Button("Refresh Repository", action: workspace.refresh)
                    .keyboardShortcut("r", modifiers: .command)
                    .disabled(workspace.selectedFolder == nil || workspace.isLoading)
                Button("Show in Finder") {
                    if let folder = workspace.selectedFolder { workspace.reveal(folder.url) }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(workspace.selectedFolder == nil)
            }
        }
    }
}
