import Foundation

public struct GitHubRepository: Codable, Hashable, Sendable {
    public let id: Int64
    public let name: String
    public let fullName: String
    public let htmlURL: URL
    public let description: String?
    public let defaultBranch: String
    public let isPrivate: Bool
    public let stars: Int
    public let openIssues: Int

    private enum CodingKeys: String, CodingKey {
        case id, name, description
        case fullName = "full_name"
        case htmlURL = "html_url"
        case defaultBranch = "default_branch"
        case isPrivate = "private"
        case stars = "stargazers_count"
        case openIssues = "open_issues_count"
    }
}

public struct GitHubRepositoryReference: Hashable, Sendable {
    public let owner: String
    public let name: String
    public let url: URL

    public init?(url: URL) {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "https",
              components.host?.lowercased() == "github.com",
              components.user == nil, components.password == nil,
              components.port == nil, components.query == nil, components.fragment == nil
        else { return nil }

        var path = components.percentEncodedPath
        if path.hasSuffix("/") { path.removeLast() }
        let parts = path.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].isEmpty,
              let owner = String(parts[1]).removingPercentEncoding,
              var name = String(parts[2]).removingPercentEncoding
        else { return nil }
        if name.hasSuffix(".git") { name.removeLast(4) }

        let ownerCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-")
        let nameCharacters = ownerCharacters.union(CharacterSet(charactersIn: "_."))
        guard !owner.isEmpty, !name.isEmpty, name != ".", name != "..",
              owner.unicodeScalars.allSatisfy(ownerCharacters.contains),
              name.unicodeScalars.allSatisfy(nameCharacters.contains)
        else { return nil }

        components.scheme = "https"
        components.host = "github.com"
        components.path = "/\(owner)/\(name)"
        guard let normalizedURL = components.url else { return nil }
        self.owner = owner
        self.name = name
        self.url = normalizedURL
    }
}
