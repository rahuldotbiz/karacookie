import Foundation
import Combine
import AppKit
import SwiftUI

struct CurrentLine: Equatable {
    let text: String
    let startMs: Int
    let endMs: Int
    let words: [WordTiming]
}

enum OverlayState: Equatable {
    case loading
    case idle(message: String)
    case noLyrics(track: String, artist: String)
    case ad
    case podcast(title: String)
    case lyrics(prev: String?, current: CurrentLine, next: String?)

    static let demo: OverlayState = {
        let line = "Now it looks as though they're here to stay"
        let words = WordTimingInterpolator.interpolate(text: line, startMs: 0, endMs: 4000)
        return .lyrics(
            prev: "Yesterday all my troubles seemed so far away",
            current: CurrentLine(text: line, startMs: 0, endMs: 4000, words: words),
            next: "Oh, I believe in yesterday"
        )
    }()
}

@MainActor
final class OverlayStateBox: ObservableObject {
    @Published var state: OverlayState = .loading
    @Published var isPaused: Bool = false
    @Published var artwork: NSImage?
    @Published var accentColor: Color = Color(red: 0.42, green: 0.62, blue: 1.0)
    @Published var nowMs: Int = 0
}
