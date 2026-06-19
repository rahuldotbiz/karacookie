import Foundation

struct NowPlaying: Equatable {
    enum Kind: String { case track, episode, ad, unknown }

    struct Track: Equatable {
        let id: String              // e.g. "spotify:track:1234abcd"
        let name: String
        let artist: String
        let album: String
        let durationMs: Int
    }

    let kind: Kind
    let track: Track?
    let progressMs: Int
    let isPlaying: Bool
    let polledAt: Date
}
