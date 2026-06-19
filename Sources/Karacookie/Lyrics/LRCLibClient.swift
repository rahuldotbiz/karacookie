import Foundation

struct LRCLibResult: Codable {
    let id: Int?
    let trackName: String?
    let artistName: String?
    let albumName: String?
    let duration: Double?
    let instrumental: Bool?
    let plainLyrics: String?
    let syncedLyrics: String?
}

enum LRCLibError: Error {
    case network(Error)
    case http(Int)
    case decode(Error)
}

@MainActor
final class LRCLibClient {
    private let session: URLSession
    private let userAgent = "KaraokeBar/0.1 (+https://github.com/karaokebar/karaokebar)"
    private let base = URL(string: "https://lrclib.net/api")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Exact match (preferred). Returns nil on 404.
    func get(track: String, artist: String, album: String, durationSec: Int) async throws -> LRCLibResult? {
        var comps = URLComponents(url: base.appendingPathComponent("get"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "track_name", value: track),
            .init(name: "artist_name", value: artist),
            .init(name: "album_name", value: album),
            .init(name: "duration", value: String(durationSec))
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response): (Data, URLResponse)
        do { (data, response) = try await session.data(for: req) }
        catch { throw LRCLibError.network(error) }
        let http = response as! HTTPURLResponse
        if http.statusCode == 404 { return nil }
        guard (200..<300).contains(http.statusCode) else { throw LRCLibError.http(http.statusCode) }

        do { return try JSONDecoder().decode(LRCLibResult.self, from: data) }
        catch { throw LRCLibError.decode(error) }
    }

    /// Fuzzy search, picks closest by duration. Returns nil if nothing matches reasonably.
    func search(track: String, artist: String, durationSec: Int) async throws -> LRCLibResult? {
        var comps = URLComponents(url: base.appendingPathComponent("search"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "track_name", value: track),
            .init(name: "artist_name", value: artist)
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response): (Data, URLResponse)
        do { (data, response) = try await session.data(for: req) }
        catch { throw LRCLibError.network(error) }
        let http = response as! HTTPURLResponse
        guard (200..<300).contains(http.statusCode) else { throw LRCLibError.http(http.statusCode) }

        let results: [LRCLibResult]
        do { results = try JSONDecoder().decode([LRCLibResult].self, from: data) }
        catch { throw LRCLibError.decode(error) }

        // Prefer entries with syncedLyrics, then closest duration.
        let viable = results.filter { ($0.syncedLyrics?.isEmpty == false) || ($0.plainLyrics?.isEmpty == false) }
        let target = Double(durationSec)
        return viable.min { a, b in
            let da = abs((a.duration ?? target) - target)
            let db = abs((b.duration ?? target) - target)
            return da < db
        }
    }
}
