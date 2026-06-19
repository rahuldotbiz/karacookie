import Foundation

/// Tiny disk + in-memory cache for LRCLib responses, keyed by Spotify track ID.
@MainActor
final class LyricsCache {
    private let dir: URL
    private var memory: [String: LRCLibResult] = [:]
    private var order: [String] = []
    private let memoryLimit = 50

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.dir = caches.appendingPathComponent("Karaoke Bar/lyrics", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    func get(_ spotifyId: String) -> LRCLibResult? {
        if let hit = memory[spotifyId] { return hit }
        let file = dir.appendingPathComponent("\(spotifyId).json")
        guard let data = try? Data(contentsOf: file),
              let decoded = try? JSONDecoder().decode(LRCLibResult.self, from: data)
        else { return nil }
        promote(spotifyId, decoded)
        return decoded
    }

    func set(_ spotifyId: String, _ result: LRCLibResult) {
        promote(spotifyId, result)
        let file = dir.appendingPathComponent("\(spotifyId).json")
        if let data = try? JSONEncoder().encode(result) {
            try? data.write(to: file, options: .atomic)
        }
    }

    private func promote(_ key: String, _ value: LRCLibResult) {
        memory[key] = value
        order.removeAll { $0 == key }
        order.append(key)
        while order.count > memoryLimit {
            let drop = order.removeFirst()
            memory[drop] = nil
        }
    }
}
