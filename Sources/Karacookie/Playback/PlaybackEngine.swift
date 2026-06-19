import Foundation
import Combine
import SwiftUI

@MainActor
final class PlaybackEngine {
    private let sources: SourceManager
    private let lyricsService: LyricsService
    private let stateBox: OverlayStateBox
    private let artFetcher = AlbumArtFetcher()

    private var currentTrackId: String?
    private var lyrics: [LRCLine] = []
    private var lastNowPlaying: NowPlaying?
    private var fetchTask: Task<Void, Never>?
    private var artTask: Task<Void, Never>?

    private var lastSpotifyProgressMs: Int = 0
    private var lastSpotifySyncedAt: Date = .distantPast
    private var lastIsPlaying: Bool = false
    private var lastLineIndex: Int = -1

    private var timer: Timer?
    private var cancellables: Set<AnyCancellable> = []

    init(sources: SourceManager, lyricsService: LyricsService, stateBox: OverlayStateBox) {
        self.sources = sources
        self.lyricsService = lyricsService
        self.stateBox = stateBox
    }

    func start() {
        sources.$nowPlaying
            .sink { [weak self] np in self?.handle(np) }
            .store(in: &cancellables)

        sources.$status
            .removeDuplicates()
            .sink { [weak self] _ in self?.refreshIdleMessage() }
            .store(in: &cancellables)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        cancellables.removeAll()
        fetchTask?.cancel()
        lyrics = []
        currentTrackId = nil
        lastSpotifySyncedAt = .distantPast
        lastLineIndex = -1
    }

    private func handle(_ np: NowPlaying?) {
        guard let np else {
            currentTrackId = nil
            lyrics = []
            lastLineIndex = -1
            stateBox.isPaused = false
            stateBox.state = .idle(message: idleMessageForStatus())
            return
        }

        lastNowPlaying = np
        lastIsPlaying = np.isPlaying
        lastSpotifyProgressMs = np.progressMs
        lastSpotifySyncedAt = np.polledAt
        stateBox.isPaused = !np.isPlaying

        switch np.kind {
        case .ad:
            stateBox.state = .ad
            lyrics = []
            currentTrackId = nil
            lastLineIndex = -1

        case .episode:
            stateBox.state = .podcast(title: np.track?.name ?? "Podcast")
            lyrics = []
            currentTrackId = nil
            lastLineIndex = -1

        case .track, .unknown:
            guard let t = np.track else { return }
            if t.id != currentTrackId {
                currentTrackId = t.id
                lyrics = []
                lastLineIndex = -1
                stateBox.state = .idle(message: "Loading lyrics…")
                fetchLyrics(for: t)
                fetchArtwork(for: t)
            }
        }
    }

    private func fetchArtwork(for track: NowPlaying.Track) {
        artTask?.cancel()
        stateBox.artwork = nil
        artTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let img = await self.artFetcher.fetch(for: track)
            guard !Task.isCancelled, self.currentTrackId == track.id else { return }
            self.stateBox.artwork = img
            if let img {
                let ns = DominantColor.extract(from: img)
                self.stateBox.accentColor = Color(nsColor: ns)
            }
        }
    }

    private func fetchLyrics(for track: NowPlaying.Track) {
        fetchTask?.cancel()
        fetchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let kind = await self.lyricsService.lyrics(for: track)
            guard !Task.isCancelled, self.currentTrackId == track.id else { return }
            switch kind {
            case .synced(let lines):
                self.lyrics = lines
            case .plain, .none:
                self.lyrics = []
                self.stateBox.state = .noLyrics(track: track.name, artist: track.artist)
            }
        }
    }

    private func tick() {
        guard !lyrics.isEmpty else { return }
        let nowMs = estimatedPositionMs()
        stateBox.nowMs = nowMs

        let idx = findLineIndex(at: nowMs) ?? 0
        if idx != lastLineIndex {
            lastLineIndex = idx
            publishLine(idx)
        }
    }

    private func publishLine(_ idx: Int) {
        let line = lyrics[idx]
        let nextStartMs: Int
        if idx + 1 < lyrics.count {
            nextStartMs = lyrics[idx + 1].timeMs
        } else if let dur = lastNowPlaying?.track?.durationMs {
            nextStartMs = dur
        } else {
            nextStartMs = line.timeMs + 5000
        }
        let displayText = line.text.isEmpty ? " " : line.text
        let words = WordTimingInterpolator.interpolate(
            text: displayText, startMs: line.timeMs, endMs: nextStartMs
        )
        let current = CurrentLine(
            text: displayText,
            startMs: line.timeMs,
            endMs: nextStartMs,
            words: words
        )
        stateBox.state = .lyrics(
            prev: idx > 0 ? lyrics[idx - 1].text : nil,
            current: current,
            next: idx + 1 < lyrics.count ? lyrics[idx + 1].text : nil
        )
    }

    private func refreshIdleMessage() {
        if case .idle = stateBox.state {
            stateBox.state = .idle(message: idleMessageForStatus())
        }
    }

    private func idleMessageForStatus() -> String {
        switch sources.status {
        case .noPermission:
            return "Allow Karacookie in System Settings →\nPrivacy & Security → Automation"
        case .notRunning:
            return "Open Spotify or Apple Music\nand press Play"
        case .stopped:
            return "Press Play in Spotify or Apple Music"
        case .paused:
            return "Paused"
        case .error(let m):
            return "Error: \(m.prefix(80))"
        case .unknown:
            return "Connecting…"
        case .playing:
            return "Loading lyrics…"
        }
    }

    private func estimatedPositionMs() -> Int {
        guard lastSpotifySyncedAt > .distantPast else { return lastSpotifyProgressMs }
        if !lastIsPlaying { return lastSpotifyProgressMs }
        let elapsed = Date().timeIntervalSince(lastSpotifySyncedAt) * 1000
        return lastSpotifyProgressMs + Int(elapsed)
    }

    private func findLineIndex(at ms: Int) -> Int? {
        guard !lyrics.isEmpty else { return nil }
        var lo = 0, hi = lyrics.count - 1, ans = -1
        while lo <= hi {
            let mid = (lo + hi) / 2
            if lyrics[mid].timeMs <= ms {
                ans = mid
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }
        return ans >= 0 ? ans : nil
    }
}
