// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GitWorkspace",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "GitEngine", targets: ["GitEngine"]),
        .library(name: "GitHubKit", targets: ["GitHubKit"]),
        .library(name: "WorkspaceCore", targets: ["WorkspaceCore"]),
        .executable(name: "GitWorkspace", targets: ["GitWorkspace"]),
    ],
    targets: [
        .target(name: "GitEngine"),
        .testTarget(name: "GitEngineTests", dependencies: ["GitEngine"]),
        .target(name: "GitHubKit"),
        .testTarget(name: "GitHubKitTests", dependencies: ["GitHubKit"]),
        .target(name: "WorkspaceCore", dependencies: ["GitEngine", "GitHubKit"]),
        .testTarget(name: "WorkspaceCoreTests", dependencies: ["WorkspaceCore"]),
        .executableTarget(
            name: "GitWorkspace",
            dependencies: ["GitEngine", "GitHubKit", "WorkspaceCore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
