import Foundation

enum SourceStatus: Equatable {
    case unknown
    case playing
    case paused
    case stopped
    case notRunning
    case noPermission
    case error(String)
}

enum SourcePreference: String, CaseIterable, Identifiable {
    case auto, spotify, appleMusic
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .auto:       return "Auto (whichever is playing)"
        case .spotify:    return "Spotify only"
        case .appleMusic: return "Apple Music only"
        }
    }
}
