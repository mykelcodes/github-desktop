import GitEngine
import GitHubKit
import SwiftUI

struct RepositoryView: View {
    let snapshot: RepositorySnapshot
    let workspace: WorkspaceModel
    @State private var destination = "Local"
    @State private var selectedFileID: String?

    private var selectedChange: FileChange? {
        snapshot.changes.first { $0.id == selectedFileID }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 25, weight: .light))
                        .frame(width: 50, height: 50)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(snapshot.rootURL.lastPathComponent).font(.title2.weight(.semibold))
                        Text(snapshot.rootURL.path).font(.caption).foregroundStyle(.secondary)
                            .textSelection(.enabled).lineLimit(1).truncationMode(.middle)
                    }
                    Spacer(minLength: 12)
                    Button { workspace.reveal(snapshot.rootURL) } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }
                }
                HStack(spacing: 18) {
                    Label(snapshot.branch ?? "Detached HEAD", systemImage: "arrow.triangle.branch")
                        .font(.subheadline.weight(.medium))
                    if let upstream = snapshot.upstream {
                        Text(upstream).foregroundStyle(.secondary)
                        Label("\(snapshot.ahead)", systemImage: "arrow.up")
                        Label("\(snapshot.behind)", systemImage: "arrow.down")
                    } else {
                        Text(snapshot.headSHA == nil ? "No commits yet" : "No tracking branch")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(snapshot.inspectedAt, style: .time).foregroundStyle(.tertiary)
                        .help("Last read from disk")
                }
                .font(.caption)
                if snapshot.filtersDisabled {
                    Label("Custom Git filters are disabled for inspection. Filtered files may appear modified.", systemImage: "info.circle")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Picker("Repository destination", selection: $destination) {
                    Text("Local").tag("Local")
                    Text("GitHub").tag("GitHub")
                }
                .pickerStyle(.segmented).frame(width: 220)
            }
            .padding(24)
            Divider()
            if destination == "Local" {
                changesView
            } else {
                GitHubConnectionView(remotes: snapshot.remotes)
            }
        }
        .onChange(of: snapshot.changes, initial: true) { _, changes in
            if !changes.contains(where: { $0.id == selectedFileID }) {
                selectedFileID = changes.first?.id
            }
        }
    }

    private var changesView: some View {
        HSplitView {
            VStack(spacing: 0) {
                HStack {
                    Text("Changes").font(.headline)
                    Spacer()
                    Text("\(snapshot.changes.count)")
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(.quaternary, in: Capsule())
                }
                .padding(16)
                Divider()
                if snapshot.changes.isEmpty {
                    VStack(spacing: 9) {
                        Image(systemName: "checkmark.circle").font(.title2).foregroundStyle(.green)
                        Text("Working tree clean").font(.subheadline.weight(.medium))
                        Text("No local changes.").font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(snapshot.changes, selection: $selectedFileID) { change in
                        FileChangeRow(change: change).tag(change.id)
                    }
                    .listStyle(.inset)
                }
                Divider()
                Text("Refresh with ⌘R or return to this window. Submodule working trees are not inspected.")
                    .font(.caption2).foregroundStyle(.secondary)
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minWidth: 225, idealWidth: 285, maxWidth: 400)
            Group {
                if let change = selectedChange {
                    ChangeDetailView(snapshot: snapshot, change: change, git: workspace.git)
                } else {
                    ContentUnavailableView {
                        Label("All caught up", systemImage: "checkmark.seal")
                    } description: {
                        Text("Changes from your editor will appear here after a refresh.")
                    }
                }
            }
            .frame(minWidth: 350, maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct FileChangeRow: View {
    let change: FileChange

    private var status: String {
        if change.isConflicted { return "Conflict" }
        if change.isUntracked { return "New" }
        if change.indexStatus != "." && change.indexStatus != " " { return "Staged" }
        return "Modified"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: change.isConflicted ? "exclamationmark.triangle" : "doc.text")
                .foregroundStyle(change.isConflicted ? .orange : .secondary)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(change.path).lineLimit(2).truncationMode(.middle)
                    .font(.system(size: 12, weight: .medium))
                HStack(spacing: 6) {
                    Text(status)
                    if change.hasStagedChanges && change.hasUnstagedChanges && !change.isUntracked {
                        Text("+ unstaged")
                    }
                }
                .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }
}

private struct ChangeDetailView: View {
    let snapshot: RepositorySnapshot
    let change: FileChange
    let git: GitRepositoryService
    @State private var staged = false
    @State private var diff = ""
    @State private var error: String?
    @State private var loading = false

    private var showingStaged: Bool { change.hasStagedChanges && (!change.hasUnstagedChanges || staged) }
    private var requestKey: String {
        "\(change.id)|\(showingStaged)|\(snapshot.inspectedAt.timeIntervalSince1970)"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(change.path).font(.subheadline.weight(.medium))
                        .lineLimit(1).truncationMode(.middle).textSelection(.enabled)
                    if let original = change.originalPath {
                        Text("Renamed from \(original)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if change.hasStagedChanges && change.hasUnstagedChanges && !change.isUntracked {
                    Picker("Changes to inspect", selection: $staged) {
                        Text("Unstaged").tag(false)
                        Text("Staged").tag(true)
                    }
                    .pickerStyle(.segmented).frame(width: 170)
                } else {
                    Text(change.isUntracked ? "Untracked file" : showingStaged ? "Staged changes" : "Unstaged changes")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(16)
            Divider()
            if loading {
                ProgressView("Reading changes…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                ContentUnavailableView("Preview unavailable", systemImage: "doc.badge.ellipsis", description: Text(error))
            } else if diff.isEmpty {
                ContentUnavailableView("No text changes", systemImage: "doc", description: Text("Refresh the repository if this file changed outside the app."))
            } else {
                NativeDiffView(text: diff)
            }
        }
        .task(id: requestKey) {
            loading = true
            error = nil
            do {
                let text = try await git.diff(in: snapshot.rootURL, change: change, staged: showingStaged)
                guard !Task.isCancelled else { return }
                let limit = 250_000
                diff = text.count > limit
                    ? String(text.prefix(limit)) + "\n\nPreview limited to 250,000 characters. Open the file in your editor for the full contents."
                    : text
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error.localizedDescription
            }
            loading = false
        }
    }
}
