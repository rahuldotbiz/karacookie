import AppKit

@MainActor
final class AlbumArtFetcher {
    private let session: URLSession
    private var memory: [String: NSImage] = [:]
    private var order: [String] = []
    private let memoryLimit = 50
    private let diskDir: URL

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.diskDir = caches.appendingPathComponent("Karacookie/art", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskDir, withIntermediateDirectories: true)
        self.session = URLSession.shared
    }

    func fetch(for track: NowPlaying.Track) async -> NSImage? {
        let key = track.id
        if let hit = memory[key] { return hit }
        if let disk = loadDisk(key) {
            promote(key, disk)
            return disk
        }
        // oEmbed only works for Spotify URIs.
        if track.id.hasPrefix("spotify:"), let img = await fetchOEmbed(track) {
            saveDisk(key, img)
            promote(key, img)
            return img
        }
        if let img = await fetchITunes(track) {
            saveDisk(key, img)
            promote(key, img)
            return img
        }
        return nil
    }

    private func fetchOEmbed(_ track: NowPlaying.Track) async -> NSImage? {
        guard let trackIdOnly = track.id.split(separator: ":").last.map(String.init) else { return nil }
        let urlStr = "https://open.spotify.com/oembed?url=https://open.spotify.com/track/\(trackIdOnly)"
        guard let url = URL(string: urlStr) else { return nil }
        struct R: Decodable { let thumbnail_url: String? }
        do {
            let (data, _) = try await session.data(from: url)
            let r = try JSONDecoder().decode(R.self, from: data)
            guard let thumbStr = r.thumbnail_url, let thumbURL = URL(string: thumbStr) else { return nil }
            let (imgData, _) = try await session.data(from: thumbURL)
            return NSImage(data: imgData)
        } catch {
            return nil
        }
    }

    private func fetchITunes(_ track: NowPlaying.Track) async -> NSImage? {
        let raw = "\(track.artist) \(track.name)"
        guard let q = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        guard let url = URL(string: "https://itunes.apple.com/search?term=\(q)&entity=song&limit=1") else { return nil }
        struct R: Decodable {
            let results: [Item]
            struct Item: Decodable { let artworkUrl100: String? }
        }
        do {
            let (data, _) = try await session.data(from: url)
            let r = try JSONDecoder().decode(R.self, from: data)
            guard let small = r.results.first?.artworkUrl100 else { return nil }
            let big = small.replacingOccurrences(of: "100x100bb.jpg", with: "600x600bb.jpg")
            guard let imgURL = URL(string: big) else { return nil }
            let (imgData, _) = try await session.data(from: imgURL)
            return NSImage(data: imgData)
        } catch {
            return nil
        }
    }

    private func loadDisk(_ key: String) -> NSImage? {
        let file = diskDir.appendingPathComponent(safeFilename(key) + ".jpg")
        guard let data = try? Data(contentsOf: file) else { return nil }
        return NSImage(data: data)
    }

    private func saveDisk(_ key: String, _ image: NSImage) {
        let file = diskDir.appendingPathComponent(safeFilename(key) + ".jpg")
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let jpeg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.85])
        else { return }
        try? jpeg.write(to: file, options: .atomic)
    }

    private func safeFilename(_ s: String) -> String {
        s.replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "/", with: "_")
    }

    private func promote(_ key: String, _ img: NSImage) {
        memory[key] = img
        order.removeAll { $0 == key }
        order.append(key)
        while order.count > memoryLimit {
            let drop = order.removeFirst()
            memory[drop] = nil
        }
    }
}
