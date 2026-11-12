import Foundation

struct GitStatus: Sendable {
    var branch: String?
    var headSHA: String?
    var upstream: String?
    var ahead = 0
    var behind = 0
    var changes: [FileChange] = []
}

enum GitOutputParser {
    static func status(_ data: Data) throws -> GitStatus {
        let records = try data.split(separator: 0).map { bytes -> String in
            guard let value = String(bytes: bytes, encoding: .utf8) else { throw GitRepositoryError.invalidOutput }
            return value
        }
        var result = GitStatus()
        var index = 0
        while index < records.count {
            let record = records[index]
            index += 1
            if record.hasPrefix("# branch.oid ") {
                let value = String(record.dropFirst(13))
                result.headSHA = value == "(initial)" ? nil : value
            } else if record.hasPrefix("# branch.head ") {
                let value = String(record.dropFirst(14))
                result.branch = value == "(detached)" ? nil : value
            } else if record.hasPrefix("# branch.upstream ") {
                result.upstream = String(record.dropFirst(18))
            } else if record.hasPrefix("# branch.ab ") {
                let counts = record.dropFirst(12).split(separator: " ")
                guard counts.count == 2, let ahead = Int(counts[0]), let behind = Int(counts[1]) else {
                    throw GitRepositoryError.invalidOutput
                }
                result.ahead = ahead
                result.behind = -behind
            } else if record.hasPrefix("? ") {
                result.changes.append(FileChange(path: String(record.dropFirst(2)), indexStatus: ".",
                                                 worktreeStatus: "?", isUntracked: true))
            } else if let kind = record.first, "12u".contains(kind) {
                let fieldCount = kind == "1" ? 9 : kind == "2" ? 10 : 11
                let fields = record.split(separator: " ", maxSplits: fieldCount - 1, omittingEmptySubsequences: false)
                guard fields.count == fieldCount, fields[1].count == 2 else { throw GitRepositoryError.invalidOutput }
                var originalPath: String?
                if kind == "2" {
                    guard index < records.count else { throw GitRepositoryError.invalidOutput }
                    originalPath = records[index]
                    index += 1
                }
                result.changes.append(FileChange(path: String(fields[fieldCount - 1]), originalPath: originalPath,
                                                 indexStatus: String(fields[1].prefix(1)),
                                                 worktreeStatus: String(fields[1].suffix(1)), isConflicted: kind == "u"))
            }
        }
        return result
    }

    static func remotes(_ data: Data) throws -> [GitRemote] {
        var values: [String: (fetch: String?, push: String?)] = [:]
        for bytes in data.split(separator: 0) {
            guard let record = String(bytes: bytes, encoding: .utf8), let separator = record.firstIndex(of: "\n") else {
                throw GitRepositoryError.invalidOutput
            }
            let key = record[..<separator]
            let rawURL = String(record[record.index(after: separator)...])
            guard key.hasPrefix("remote.") else { continue }
            if key.hasSuffix(".pushurl") {
                let name = String(key.dropFirst(7).dropLast(8))
                if values[name]?.push == nil { values[name, default: (nil, nil)].push = rawURL }
            } else if key.hasSuffix(".url") {
                let name = String(key.dropFirst(7).dropLast(4))
                if values[name]?.fetch == nil { values[name, default: (nil, nil)].fetch = rawURL }
            }
        }
        return values.keys.sorted().map { name in
            let urls = values[name]!
            return GitRemote(name: name, fetchURL: urls.fetch.map(redact),
                             pushURL: (urls.push ?? urls.fetch).map(redact),
                             githubURL: urls.fetch.flatMap(githubURL))
        }
    }

    static func redact(_ text: String) -> String {
        var result = text.replacingOccurrences(of: #"([A-Za-z][A-Za-z0-9+.-]*://)[^\s/@]+@"#,
                                              with: "$1[redacted]@", options: .regularExpression)
        result = result.replacingOccurrences(of: #"([A-Za-z][A-Za-z0-9+.-]*://[^\s?#]+)[?#][^\s]*"#,
                                            with: "$1", options: .regularExpression)
        return result
    }

    static func githubURL(_ remote: String) -> URL? {
        let path: String
        if let components = URLComponents(string: remote),
           let scheme = components.scheme, ["https", "http", "ssh", "git"].contains(scheme.lowercased()),
           components.host?.lowercased() == "github.com", components.port == nil {
            path = components.path
        } else if remote.hasPrefix("git@github.com:") {
            path = String(remote.dropFirst("git@github.com:".count))
        } else {
            return nil
        }
        let trimmed = path.hasSuffix(".git") ? String(path.dropLast(4)) : path
        let parts = trimmed.split(separator: "/", omittingEmptySubsequences: true)
        guard parts.count == 2,
              parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && $0.range(of: #"^[A-Za-z0-9_.-]+$"#, options: .regularExpression) != nil }) else {
            return nil
        }
        return URL(string: "https://github.com/\(parts[0])/\(parts[1])")
    }
}
