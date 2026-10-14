import Foundation

// MARK: - Lyrics Service (LRCLIB API — open source, no key needed)
@MainActor
final class LyricsService {

    private let baseURL = "https://lrclib.net/api"
    private var cache: [String: [LRCLine]] = [:]

    func fetchLyrics(title: String, artist: String, durationSeconds: Double) async -> Result<[LRCLine], Error> {
        let cacheKey = "\(title.lowercased())|\(artist.lowercased())"
        if let cached = cache[cacheKey] {
            return .success(cached)
        }

        // 1. Try exact match with duration
        if let lines = await fetchFromLRCLIB(title: title, artist: artist, duration: durationSeconds) {
            cache[cacheKey] = lines
            return .success(lines)
        }

        // 2. Try search endpoint
        if let lines = await searchLRCLIB(title: title, artist: artist) {
            cache[cacheKey] = lines
            return .success(lines)
        }

        // 3. Fallback: clean title (remove "feat.", "Remastered", etc.)
        let cleaned = cleanTitle(title)
        if cleaned != title {
            if let lines = await searchLRCLIB(title: cleaned, artist: artist) {
                cache[cacheKey] = lines
                return .success(lines)
            }
        }

        return .failure(LyricsError.notFound)
    }

    // MARK: - LRCLIB GET (exact match)
    private func fetchFromLRCLIB(title: String, artist: String, duration: Double) async -> [LRCLine]? {
        guard var components = URLComponents(string: "\(baseURL)/get") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "track_name", value: title),
            URLQueryItem(name: "artist_name", value: artist),
            URLQueryItem(name: "duration", value: String(Int(duration)))
        ]
        guard let url = components.url else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let json = try JSONDecoder().decode(LRCLIBResponse.self, from: data)
            if let syncedLyrics = json.syncedLyrics, !syncedLyrics.isEmpty {
                return parseLRC(syncedLyrics)
            }
        } catch {}
        return nil
    }

    // MARK: - LRCLIB Search (fallback)
    private func searchLRCLIB(title: String, artist: String) async -> [LRCLine]? {
        guard var components = URLComponents(string: "\(baseURL)/search") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "track_name", value: title),
            URLQueryItem(name: "artist_name", value: artist),
            URLQueryItem(name: "q", value: "\(title) \(artist)")
        ]
        guard let url = components.url else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let results = try JSONDecoder().decode([LRCLIBResponse].self, from: data)
            if let best = results.first(where: { ($0.syncedLyrics?.isEmpty == false) }),
               let syncedLyrics = best.syncedLyrics {
                return parseLRC(syncedLyrics)
            }
        } catch {}
        return nil
    }

    // MARK: - Clean Title Helper
    private func cleanTitle(_ title: String) -> String {
        var result = title
        let patterns = [
            "\\s*\\((feat\\.|featuring|with|remastered|deluxe|version).*?\\)",
            "\\s*\\[(feat\\.|featuring|with|remastered|deluxe|version).*?\\]",
            "\\s*-\\s*(remastered|deluxe|single|bonus|live|radio edit).*?$"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: "")
            }
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - LRC Parser
    func parseLRC(_ lrc: String) -> [LRCLine] {
        var lines: [LRCLine] = []
        let rawLines = lrc.components(separatedBy: "\n")

        for rawLine in rawLines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("[") else { continue }
            guard let closeBracket = trimmed.firstIndex(of: "]") else { continue }

            let timeStr = String(trimmed[trimmed.index(after: trimmed.startIndex)..<closeBracket])
            let text = String(trimmed[trimmed.index(after: closeBracket)...]).trimmingCharacters(in: .whitespaces)

            guard let first = timeStr.first, first.isNumber else { continue }

            if let seconds = parseLRCTimestamp(timeStr), !text.isEmpty {
                lines.append(LRCLine(timeSeconds: seconds, text: text))
            }
        }
        return lines.sorted { $0.timeSeconds < $1.timeSeconds }
    }

    private func parseLRCTimestamp(_ str: String) -> Double? {
        let parts = str.components(separatedBy: ":")
        guard parts.count == 2,
              let minutes = Double(parts[0]) else { return nil }
        let secParts = parts[1].components(separatedBy: ".")
        guard let seconds = Double(secParts[0]) else { return nil }
        let centiseconds: Double
        if secParts.count > 1 {
            let csStr = secParts[1]
            if csStr.count <= 2 {
                centiseconds = (Double(csStr) ?? 0) / 100.0
            } else {
                centiseconds = (Double(csStr) ?? 0) / 1000.0
            }
        } else {
            centiseconds = 0
        }
        return minutes * 60.0 + seconds + centiseconds
    }
}

// MARK: - LRCLIB Response Model
struct LRCLIBResponse: Codable, Sendable {
    let id: Int?
    let name: String?
    let trackName: String?
    let artistName: String?
    let albumName: String?
    let duration: Double?
    let instrumental: Bool?
    let plainLyrics: String?
    let syncedLyrics: String?
}

// MARK: - Error
enum LyricsError: LocalizedError {
    case notFound
    var errorDescription: String? { "Lyrics not found." }
}
