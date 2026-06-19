import Foundation
import Combine

/// Coordinates Spotify + Apple Music monitors based on user preference.
@MainActor
final class SourceManager: ObservableObject {
    @Published private(set) var nowPlaying: NowPlaying?
    @Published private(set) var status: SourceStatus = .unknown
    @Published private(set) var activeSourceName: String = ""

    let spotify = SpotifyAppleScriptMonitor()
    let appleMusic = AppleMusicAppleScriptMonitor()
    private var cancellables: Set<AnyCancellable> = []

    func start() {
        spotify.start()
        appleMusic.start()

        Publishers.CombineLatest(spotify.$nowPlaying, appleMusic.$nowPlaying)
            .sink { [weak self] s, m in self?.combine(spotify: s, appleMusic: m) }
            .store(in: &cancellables)

        Publishers.CombineLatest(spotify.$status, appleMusic.$status)
            .sink { [weak self] _, _ in self?.combineStatus() }
            .store(in: &cancellables)
    }

    func stop() {
        spotify.stop()
        appleMusic.stop()
        cancellables.removeAll()
    }

    func openAutomationSettings() { spotify.openAutomationSettings() }

    private var preference: SourcePreference {
        let raw = UserDefaults.standard.string(forKey: "sourcePreference") ?? SourcePreference.auto.rawValue
        return SourcePreference(rawValue: raw) ?? .auto
    }

    private func combine(spotify s: NowPlaying?, appleMusic m: NowPlaying?) {
        switch preference {
        case .spotify:
            nowPlaying = s
            activeSourceName = "Spotify"
        case .appleMusic:
            nowPlaying = m
            activeSourceName = "Apple Music"
        case .auto:
            if let s, s.isPlaying { nowPlaying = s; activeSourceName = "Spotify" }
            else if let m, m.isPlaying { nowPlaying = m; activeSourceName = "Apple Music" }
            else if let s { nowPlaying = s; activeSourceName = "Spotify" }
            else if let m { nowPlaying = m; activeSourceName = "Apple Music" }
            else { nowPlaying = nil; activeSourceName = "" }
        }
    }

    private func combineStatus() {
        switch preference {
        case .spotify:    status = spotify.status
        case .appleMusic: status = appleMusic.status
        case .auto:
            // Prefer playing > paused > stopped > notRunning across the two
            let candidates = [spotify.status, appleMusic.status]
            if candidates.contains(.playing) { status = .playing; return }
            if candidates.contains(.paused)  { status = .paused;  return }
            if candidates.contains(where: { if case .noPermission = $0 { true } else { false } }) {
                status = .noPermission; return
            }
            if candidates.contains(.stopped) { status = .stopped; return }
            status = spotify.status
        }
    }
}
