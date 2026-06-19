import AppKit
import Combine

@MainActor
final class SpotifyAppleScriptMonitor: ObservableObject {
    @Published private(set) var nowPlaying: NowPlaying?
    @Published private(set) var status: SourceStatus = .unknown

    private let script: NSAppleScript
    private var task: Task<Void, Never>?

    init() {
        let source = """
        if application "Spotify" is not running then return "NOT_RUNNING"
        tell application "Spotify"
            try
                set playerStateStr to (player state) as text
                if playerStateStr is "stopped" then return "STOPPED"
                set theTrack to current track
                set theID to (id of theTrack) as text
                set theName to (name of theTrack) as text
                set theArtist to (artist of theTrack) as text
                set theAlbum to (album of theTrack) as text
                set theDuration to (duration of theTrack) as text
                set thePosition to (player position) as text
                set theURL to (spotify url of theTrack) as text
                return theID & "|" & theName & "|" & theArtist & "|" & theAlbum & "|" & theDuration & "|" & thePosition & "|" & playerStateStr & "|" & theURL
            on error errMsg
                return "ERROR|" & errMsg
            end try
        end tell
        """
        guard let s = NSAppleScript(source: source) else {
            fatalError("Failed to compile Spotify AppleScript")
        }
        var compileError: NSDictionary?
        s.compileAndReturnError(&compileError)
        self.script = s
    }

    func start() {
        stop()
        task = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.tick()
                let delay = self.pollInterval()
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    func openAutomationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }

    private func pollInterval() -> Double {
        switch status {
        case .playing:    return 0.5
        case .paused:     return 2.0
        case .stopped:    return 3.0
        case .notRunning: return 5.0
        case .noPermission, .error: return 5.0
        case .unknown:    return 1.0
        }
    }

    private func tick() async {
        let running = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.spotify.client"
        }
        guard running else {
            nowPlaying = nil
            status = .notRunning
            return
        }

        var errInfo: NSDictionary?
        let descriptor = script.executeAndReturnError(&errInfo)
        if let errInfo {
            let code = (errInfo[NSAppleScript.errorNumber] as? Int) ?? 0
            if code == -1743 {
                nowPlaying = nil
                status = .noPermission
                return
            }
            let msg = (errInfo[NSAppleScript.errorBriefMessage] as? String) ?? "unknown"
            status = .error(msg)
            return
        }

        guard let raw = descriptor.stringValue else {
            status = .error("nil result")
            return
        }
        parse(raw)
    }

    private func parse(_ raw: String) {
        switch raw {
        case "NOT_RUNNING":
            nowPlaying = nil
            status = .notRunning
            return
        case "STOPPED":
            nowPlaying = nil
            status = .stopped
            return
        default:
            break
        }

        if raw.hasPrefix("ERROR|") {
            status = .error(String(raw.dropFirst(6)))
            return
        }

        let fields = raw.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard fields.count >= 8 else {
            status = .error("malformed: \(raw)")
            return
        }

        let id = fields[0]
        let name = fields[1]
        let artist = fields[2]
        let album = fields[3]
        let durationMs = Int(fields[4]) ?? 0
        let positionSec = Double(fields[5]) ?? 0
        let progressMs = Int(positionSec * 1000)
        let stateStr = fields[6]
        let isPlaying = stateStr == "playing"

        let kind: NowPlaying.Kind = id.contains(":episode:") ? .episode : .track
        let track = NowPlaying.Track(
            id: id,
            name: name,
            artist: artist,
            album: album,
            durationMs: durationMs
        )
        nowPlaying = NowPlaying(
            kind: kind,
            track: track,
            progressMs: progressMs,
            isPlaying: isPlaying,
            polledAt: Date()
        )
        status = isPlaying ? .playing : .paused
    }
}
