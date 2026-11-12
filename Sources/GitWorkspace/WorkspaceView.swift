import AppKit
import SwiftUI
import WorkspaceCore

struct WorkspaceView: View {
    @Bindable var workspace: WorkspaceModel

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: Binding(get: { workspace.selectedID }, set: { workspace.select($0) })) {
                    Section("Local Folders") {
                        ForEach(workspace.folders) { folder in
                            Label {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(folder.name).fontWeight(.medium)
                                    Text(folder.url.deletingLastPathComponent().path)
                                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                .padding(.vertical, 4)
                            } icon: {
                                Image(systemName: "folder").foregroundStyle(.secondary)
                            }
                            .tag(folder.id)
                            .help(folder.path)
                            .contextMenu {
                                Button("Show in Finder") { workspace.reveal(folder.url) }
                                Divider()
                                Button("Disconnect Folder") {
                                    Task { await workspace.disconnect(folder) }
                                }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: workspace.chooseFolder) {
                        Label("Connect Folder", systemImage: "plus")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .disabled(workspace.isConnecting)
                    HStack(spacing: 6) {
                        Circle().fill(.green).frame(width: 6, height: 6)
                        Text("Local workspace").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(workspace.folders.count)").font(.caption.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(16)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 235, max: 320)
        } detail: {
            Group {
                if let snapshot = workspace.snapshot {
                    RepositoryView(snapshot: snapshot, workspace: workspace)
                        .id(snapshot.rootURL.path)
                } else if workspace.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Reading repository…").foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = workspace.repositoryError {
                    ContentUnavailableView {
                        Label("Repository unavailable", systemImage: "folder.badge.questionmark")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Try Again", action: workspace.refresh)
                        Button("Connect Another Folder…", action: workspace.chooseFolder)
                    }
                } else {
                    WelcomeView(connect: workspace.chooseFolder, isConnecting: workspace.isConnecting)
                }
            }
            .navigationTitle(workspace.selectedFolder?.name ?? "Git Workspace")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if workspace.isLoading || workspace.isConnecting {
                        ProgressView().controlSize(.small)
                    }
                    Button(action: workspace.refresh) {
                        Label("Refresh Repository", systemImage: "arrow.clockwise")
                    }
                    .disabled(workspace.selectedFolder == nil || workspace.isLoading)
                    Button(action: workspace.chooseFolder) {
                        Label("Connect Folder", systemImage: "folder.badge.plus")
                    }
                    .disabled(workspace.isConnecting)
                }
            }
        }
        .alert("Workspace error", isPresented: Binding(
            get: { workspace.connectionError != nil },
            set: { if !$0 { workspace.connectionError = nil } }
        )) {
            Button("OK") { workspace.connectionError = nil }
        } message: {
            Text(workspace.connectionError ?? "")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            if workspace.selectedFolder != nil && !workspace.isConnecting { workspace.refresh() }
        }
    }
}

private struct WelcomeView: View {
    let connect: () -> Void
    let isConnecting: Bool

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.tint)
                .frame(width: 96, height: 96)
                .background(.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
            VStack(spacing: 10) {
                Text("Your work starts here")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                Text("Connect a local Git repository to explore its changes,\nbranches, and GitHub connection in one native workspace.")
                    .font(.body).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).lineSpacing(4)
            }
            Button(action: connect) {
                Label("Connect Folder…", systemImage: "folder.badge.plus")
                    .padding(.horizontal, 14).padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
            .disabled(isConnecting)
            Text("⌘O to connect • Your files stay where they are")
                .font(.caption).foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 36) {
                feature("Local changes", icon: "doc.text.magnifyingglass", description: "Inspect staged and\nuncommitted work.")
                feature("Repository context", icon: "arrow.triangle.branch", description: "See your branch, remotes,\nand tracking status.")
                feature("GitHub connection", icon: "network", description: "Check public repository\ndetails when you need them.")
            }
            .padding(.top, 24)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func feature(_ title: String, icon: String, description: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.title3).foregroundStyle(.secondary)
            Text(title).font(.subheadline.weight(.medium))
            Text(description).font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).lineSpacing(3)
        }
        .frame(width: 160)
    }
}
