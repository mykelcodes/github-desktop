import Foundation
import Testing
@testable import GitHubKit

@Suite(.serialized)
struct GitHubClientTests {
    @Test(arguments: [
        "https://github.com/octocat/Hello-World",
        "https://GITHUB.com/octocat/Hello-World.git",
        "https://github.com/octocat/Hello-World/",
        "https://github.com/octocat/Hello%2DWorld.git/"
    ])
    func normalizesRepositoryURLs(_ value: String) throws {
        let url = try #require(URL(string: value))
        let reference = try #require(GitHubRepositoryReference(url: url))
        #expect(reference.owner == "octocat")
        #expect(reference.name == "Hello-World")
        #expect(reference.url.absoluteString == "https://github.com/octocat/Hello-World")
    }

    @Test(arguments: [
        "http://github.com/octocat/repo",
        "https://github.com.evil.example/octocat/repo",
        "https://evilgithub.com/octocat/repo",
        "https://api.github.com/octocat/repo",
        "https://github.com:443/octocat/repo",
        "https://token@github.com/octocat/repo",
        "https://user:token@github.com/octocat/repo",
        "https://github.com/octocat/repo?token=example",
        "https://github.com/octocat/repo#readme",
        "https://github.com/octocat",
        "https://github.com/octocat/repo/issues",
        "https://github.com//octocat/repo",
        "https://github.com/octocat/repo//",
        "https://github.com/octocat/repo%2Fother",
        "https://github.com/octocat/%2E%2E",
        "https://github.com/octocat/.git",
        "https://github.com/octocat/repo%3Ftoken",
        "https://github.com/octocat/repo%20name",
        "file:///octocat/repo",
        "ssh://git@github.com/octocat/repo.git"
    ])
    func rejectsNonRepositoryAndCredentialedURLs(_ value: String) throws {
        #expect(GitHubRepositoryReference(url: try #require(URL(string: value))) == nil)
    }

    @Test
    func requestsPublicRepositoryWithPinnedVersionAndDecodesResponse() async throws {
        let client = makeClient { request in
            #expect(request.url?.absoluteString == "https://api.github.com/repos/octocat/Hello-World")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "X-GitHub-Api-Version") == "2026-03-10")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/vnd.github+json")
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
            #expect(request.value(forHTTPHeaderField: "Cookie") == nil)
            #expect(!request.httpShouldHandleCookies)
            return StubResponse(status: 200, body: repositoryJSON)
        }
        let url = try #require(URL(string: "https://github.com/octocat/Hello%2DWorld.git"))
        let reference = try #require(GitHubRepositoryReference(url: url))
        let result = try await client.repository(reference)
        #expect(result.id == 1296269)
        #expect(result.fullName == "octocat/Hello-World")
        #expect(result.htmlURL.absoluteString == "https://github.com/octocat/Hello-World")
        #expect(result.description == nil)
        #expect(result.defaultBranch == "main")
        #expect(!result.isPrivate)
        #expect(result.stars == 80)
        #expect(result.openIssues == 2)
    }

    @Test(arguments: [401, 403, 404])
    func reportsDeniedOrUnavailableWithoutClaimingPrivate(_ status: Int) async throws {
        let client = makeClient { _ in StubResponse(status: status, body: "{\"message\":\"Not Found\"}") }
        await #expect(throws: GitHubClientError.deniedOrNotFound) {
            try await client.repository(try reference())
        }
    }

    @Test
    func reportsPrimaryRateLimitReset() async throws {
        let client = makeClient { _ in
            StubResponse(status: 403, headers: ["X-RateLimit-Remaining": "0", "X-RateLimit-Reset": "2000000000"])
        }
        await #expect(throws: GitHubClientError.rateLimited(retryAfter: Date(timeIntervalSince1970: 2_000_000_000))) {
            try await client.repository(try reference())
        }
    }

    @Test
    func honorsRetryAfterBeforeReset() async throws {
        let client = makeClient { _ in
            StubResponse(status: 429, headers: ["Retry-After": "120", "X-RateLimit-Reset": "2000000000"])
        }
        let start = Date()
        do {
            _ = try await client.repository(try reference())
            Issue.record("Expected a rate limit error")
        } catch GitHubClientError.rateLimited(let date) {
            let date = try #require(date)
            #expect(date >= start.addingTimeInterval(120))
            #expect(date <= Date().addingTimeInterval(120))
        }
    }

    @Test
    func parsesHTTPDateRetryAfter() async throws {
        let client = makeClient { _ in
            StubResponse(status: 429, headers: ["Retry-After": "Wed, 18 May 2033 03:33:20 GMT"])
        }
        await #expect(throws: GitHubClientError.rateLimited(retryAfter: Date(timeIntervalSince1970: 2_000_000_000))) {
            try await client.repository(try reference())
        }
    }

    @Test
    func distinguishesSecondaryLimitFromPermissionDenied() async throws {
        let client = makeClient { _ in
            StubResponse(status: 403, body: "{\"message\":\"You have exceeded a secondary rate limit.\"}")
        }
        await #expect(throws: GitHubClientError.rateLimited(retryAfter: nil)) {
            try await client.repository(try reference())
        }
    }

    @Test(arguments: ["NaN", "-1", "Infinity"])
    func ignoresInvalidRetryIntervals(_ value: String) async throws {
        let client = makeClient { _ in StubResponse(status: 429, headers: ["Retry-After": value]) }
        await #expect(throws: GitHubClientError.rateLimited(retryAfter: nil)) {
            try await client.repository(try reference())
        }
    }

    @Test(arguments: [301, 410, 500])
    func reportsUnsupportedHTTPStatus(_ status: Int) async throws {
        let client = makeClient { _ in StubResponse(status: status) }
        await #expect(throws: GitHubClientError.unsupportedResponse(statusCode: status)) {
            try await client.repository(try reference())
        }
    }

    @Test(arguments: ["{", "{}", "<html>Unavailable</html>"])
    func rejectsInvalidResponses(_ body: String) async throws {
        let client = makeClient { _ in StubResponse(status: 200, body: body) }
        await #expect(throws: GitHubClientError.invalidResponse) {
            try await client.repository(try reference())
        }
    }

    @Test
    func rejectsOffHostRepositoryLink() async throws {
        let client = makeClient { _ in
            StubResponse(status: 200, body: repositoryJSON.replacingOccurrences(of: "https://github.com/", with: "https://example.com/"))
        }
        await #expect(throws: GitHubClientError.invalidResponse) {
            try await client.repository(try reference())
        }
    }

    @Test
    func preservesTransportFailure() async throws {
        let client = makeClient { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await client.repository(try reference())
            Issue.record("Expected an offline error")
        } catch let error as URLError {
            #expect(error.code == .notConnectedToInternet)
        }
    }
}

private func reference() throws -> GitHubRepositoryReference {
    let url = try #require(URL(string: "https://github.com/octocat/Hello-World"))
    return try #require(GitHubRepositoryReference(url: url))
}

private let repositoryJSON = """
{"id":1296269,"name":"Hello-World","full_name":"octocat/Hello-World","html_url":"https://github.com/octocat/Hello-World","description":null,"default_branch":"main","private":false,"stargazers_count":80,"open_issues_count":2,"extra_field":"ignored"}
"""

private struct StubResponse {
    let status: Int
    var headers: [String: String] = [:]
    var body: String = "{}"
}

private func makeClient(_ handler: @escaping @Sendable (URLRequest) throws -> StubResponse) -> GitHubClient {
    StubURLProtocol.registry.set(handler)
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    return GitHubClient(session: URLSession(configuration: configuration))
}

private final class StubRegistry: @unchecked Sendable {
    private let lock = NSLock()
    private var handler: (@Sendable (URLRequest) throws -> StubResponse)?

    func set(_ handler: @escaping @Sendable (URLRequest) throws -> StubResponse) {
        lock.withLock { self.handler = handler }
    }

    func response(for request: URLRequest) throws -> StubResponse {
        let current = lock.withLock { handler }
        guard let current else { throw URLError(.unknown) }
        return try current(request)
    }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    static let registry = StubRegistry()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let stub = try Self.registry.response(for: request)
            let url = try #require(request.url)
            let response = try #require(HTTPURLResponse(url: url, statusCode: stub.status, httpVersion: "HTTP/1.1", headerFields: stub.headers))
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(stub.body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
