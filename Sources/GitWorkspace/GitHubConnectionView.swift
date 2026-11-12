import GitEngine
import GitHubKit
import SwiftUI

struct GitHubConnectionView: View {
    let remotes: [GitRemote]
    @State private var repository: GitHubRepository?
    @State private var error: String?
    @State private var loading = false
    @State private var selectedRemoteID: String?
    private let client = GitHubClient()

    private var selectedRemote: GitRemote? {
        remotes.first { $0.id == selectedRemoteID } ?? remotes.first { $0.githubURL != nil } ?? remotes.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Repository connection", systemImage: "network").font(.title3.weight(.semibold))
                    Text("Inspect your configured remotes and check public GitHub repository details.")
                        .foregroundStyle(.secondary)
                }
                if remotes.isEmpty {
                    ContentUnavailableView("No remotes configured", systemImage: "network.slash", description: Text("This repository currently exists locally. Remote setup will be available in a later build."))
                } else {
                    ForEach(remotes) { remote in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "arrow.triangle.branch")
                                Text(remote.name).font(.headline)
                                Spacer()
                                if let url = remote.githubURL { Link("Open on GitHub ↗", destination: url) }
                            }
                            remoteLine("Fetch", value: remote.fetchURL)
                            if remote.pushURL != remote.fetchURL { remoteLine("Push", value: remote.pushURL) }
                        }
                        .padding(18)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                    }
                    if let url = selectedRemote?.githubURL, let reference = GitHubRepositoryReference(url: url) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                if remotes.filter({ $0.githubURL != nil }).count > 1 {
                                    Picker("Remote", selection: Binding(
                                        get: { selectedRemote?.id ?? "" },
                                        set: { selectedRemoteID = $0; repository = nil; error = nil }
                                    )) {
                                        ForEach(remotes.filter { $0.githubURL != nil }) { remote in
                                            Text(remote.name).tag(remote.id)
                                        }
                                    }
                                    .frame(maxWidth: 220)
                                    .disabled(loading)
                                }
                                Button {
                                    Task { await check(reference) }
                                } label: {
                                    Label("Check GitHub Connection", systemImage: "arrow.triangle.2.circlepath")
                                }
                                .buttonStyle(.borderedProminent).disabled(loading)
                                if loading { ProgressView().controlSize(.small) }
                            }
                            if let repository {
                                VStack(alignment: .leading, spacing: 10) {
                                    Label(repository.fullName, systemImage: "checkmark.circle.fill")
                                        .font(.headline).foregroundStyle(.green)
                                    if let description = repository.description, !description.isEmpty { Text(description) }
                                    HStack(spacing: 20) {
                                        Label(repository.defaultBranch, systemImage: "arrow.triangle.branch")
                                        Label("\(repository.stars) stars", systemImage: "star")
                                        Label(repository.isPrivate ? "Private" : "Public", systemImage: repository.isPrivate ? "lock" : "globe")
                                    }
                                    .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            if let error { Label(error, systemImage: "info.circle").foregroundStyle(.secondary).textSelection(.enabled) }
                            Text("Public repository checks do not require sign-in. Private repositories and account actions need GitHub authentication, which is not connected in this prototype.")
                                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(28).frame(maxWidth: 800, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onChange(of: remotes) { _, _ in repository = nil; error = nil }
    }

    private func remoteLine(_ label: String, value: String?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label).foregroundStyle(.secondary).frame(width: 40, alignment: .leading)
            Text(value ?? "Not configured").textSelection(.enabled).lineLimit(3)
        }
        .font(.system(.caption, design: .monospaced))
    }

    @MainActor
    private func check(_ reference: GitHubRepositoryReference) async {
        loading = true
        repository = nil
        error = nil
        defer { loading = false }
        do { repository = try await client.repository(reference) }
        catch { self.error = error.localizedDescription }
    }
}
