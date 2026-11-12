import Foundation

public enum GitHubClientError: Error, Equatable, LocalizedError, Sendable {
    case deniedOrNotFound
    case rateLimited(retryAfter: Date?)
    case invalidResponse
    case unsupportedResponse(statusCode: Int)

    public var errorDescription: String? {
        switch self {
        case .deniedOrNotFound:
            "GitHub could not provide this repository publicly. It may be private, unavailable, or access may be restricted."
        case .rateLimited(let retryAfter):
            if let retryAfter {
                "GitHub's public API rate limit was reached. Try again after \(retryAfter.formatted(date: .omitted, time: .shortened))."
            } else {
                "GitHub's public API rate limit was reached. Wait before trying again."
            }
        case .invalidResponse:
            "GitHub returned an unexpected repository response. Try again later."
        case .unsupportedResponse(let statusCode):
            "GitHub returned HTTP \(statusCode). Check the repository's current address on GitHub and try again."
        }
    }
}

public actor GitHubClient {
    private let session: URLSession
    private let redirectPolicy = NoRedirects()

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func repository(_ reference: GitHubRepositoryReference) async throws -> GitHubRepository {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = "/repos/\(reference.owner)/\(reference.name)"
        guard let url = components.url else { throw GitHubClientError.invalidResponse }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.httpShouldHandleCookies = false
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("GitHubWorkspace-Prototype", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request, delegate: redirectPolicy)
        guard let response = response as? HTTPURLResponse else {
            throw GitHubClientError.invalidResponse
        }

        if response.statusCode == 429 || (response.statusCode == 403 && isRateLimit(response, data: data)) {
            throw GitHubClientError.rateLimited(retryAfter: retryDate(response))
        }
        switch response.statusCode {
        case 200:
            do {
                let repository = try JSONDecoder().decode(GitHubRepository.self, from: data)
                guard GitHubRepositoryReference(url: repository.htmlURL) != nil else {
                    throw GitHubClientError.invalidResponse
                }
                return repository
            } catch {
                throw GitHubClientError.invalidResponse
            }
        case 401, 403, 404:
            throw GitHubClientError.deniedOrNotFound
        default:
            throw GitHubClientError.unsupportedResponse(statusCode: response.statusCode)
        }
    }

    private func isRateLimit(_ response: HTTPURLResponse, data: Data) -> Bool {
        if response.value(forHTTPHeaderField: "X-RateLimit-Remaining") == "0"
            || response.value(forHTTPHeaderField: "Retry-After") != nil {
            return true
        }
        let message = (try? JSONDecoder().decode(APIError.self, from: data))?.message.lowercased() ?? ""
        return message.contains("rate limit") || message.contains("abuse detection")
    }

    private func retryDate(_ response: HTTPURLResponse) -> Date? {
        if let value = response.value(forHTTPHeaderField: "Retry-After") {
            if let seconds = TimeInterval(value), seconds.isFinite, seconds >= 0 {
                return Date().addingTimeInterval(seconds)
            }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            if let date = formatter.date(from: value) { return date }
        }
        if let value = response.value(forHTTPHeaderField: "X-RateLimit-Reset"),
           let timestamp = TimeInterval(value), timestamp.isFinite, timestamp >= 0 {
            return Date(timeIntervalSince1970: timestamp)
        }
        return nil
    }
}

private struct APIError: Decodable {
    let message: String
}

private final class NoRedirects: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
