import Foundation

enum LyricsKind: Equatable {
    case synced([LRCLine])
    case plain(String)
    case none
}

@MainActor
final class LyricsService {
    private let client: LRCLibClient
    private let cache: LyricsCache

    init(client: LRCLibClient, cache: LyricsCache) {
        self.client = client
        self.cache = cache
    }

    convenience init() {
        self.init(client: LRCLibClient(), cache: LyricsCache())
    }

    /// Fetch lyrics for a track, using cache first, then `/api/get`, then `/api/search`.
    func lyrics(for track: NowPlaying.Track) async -> LyricsKind {
        if let hit = cache.get(track.id) {
            return decode(hit)
        }

        let durationSec = max(0, track.durationMs / 1000)
        do {
            if let r = try await client.get(track: track.name, artist: track.artist,
                                            album: track.album, durationSec: durationSec) {
                cache.set(track.id, r)
                return decode(r)
            }
        } catch {
            NSLog("LRCLib get failed: \(error)")
        }

        do {
            if let r = try await client.search(track: track.name, artist: track.artist,
                                               durationSec: durationSec) {
                cache.set(track.id, r)
                return decode(r)
            }
        } catch {
            NSLog("LRCLib search failed: \(error)")
        }

        return .none
    }

    private func decode(_ r: LRCLibResult) -> LyricsKind {
        if let synced = r.syncedLyrics, !synced.isEmpty {
            let parsed = LRCParser.parse(synced)
            if !parsed.isEmpty { return .synced(parsed) }
        }
        if let plain = r.plainLyrics, !plain.isEmpty {
            return .plain(plain)
        }
        return .none
    }
}
