import SwiftUI

enum ThemePresets {
    static let minimal = Theme(
        id: "minimal",
        displayName: "Minimal",
        blurb: "Pure text, transparent. Lowest distraction.",
        backdrop: .none,
        typography: TypographyStyle(prevSize: 14, currentSize: 19, nextSize: 14,
                                    currentWeight: .semibold, italic: false, tracking: -0.2),
        accent: .fixed(red: 0.82, green: 0.82, blue: 0.82),
        layout: .threeLine,
        glow: nil,
        prevNextOpacity: 0.45,
        crossfadeSeconds: 0.22
    )

    static let crystal = Theme(
        id: "crystal",
        displayName: "Crystal",
        blurb: "Frosted glass. Refined and clean.",
        backdrop: .glass(.hud),
        typography: TypographyStyle(prevSize: 15, currentSize: 22, nextSize: 15,
                                    currentWeight: .bold, italic: false, tracking: -0.3),
        accent: .perTrack(saturationBoost: 0.0),
        layout: .threeLine,
        glow: nil,
        prevNextOpacity: 0.55,
        crossfadeSeconds: 0.22
    )

    static let bloom = Theme(
        id: "bloom",
        displayName: "Bloom",
        blurb: "Album art blooms behind the lyrics. Mood follows the song.",
        backdrop: .albumArtBlur(radius: 70, tintBlack: 0.42),
        typography: TypographyStyle(prevSize: 15, currentSize: 24, nextSize: 15,
                                    currentWeight: .bold, italic: false, tracking: -0.4),
        accent: .perTrack(saturationBoost: 0.15),
        layout: .threeLine,
        glow: GlowSpec(useAccent: true, radius: 10, opacity: 0.45),
        prevNextOpacity: 0.55,
        crossfadeSeconds: 0.28
    )

    static let spotlight = Theme(
        id: "spotlight",
        displayName: "Spotlight",
        blurb: "One line, big, with a stage light behind it.",
        backdrop: .radialLight,
        typography: TypographyStyle(prevSize: 0, currentSize: 32, nextSize: 0,
                                    currentWeight: .bold, italic: false, tracking: -0.5),
        accent: .perTrack(saturationBoost: 0.0),
        layout: .singleBig,
        glow: GlowSpec(useAccent: true, radius: 18, opacity: 0.55),
        prevNextOpacity: 0,
        crossfadeSeconds: 0.26
    )

    static let concert = Theme(
        id: "concert",
        displayName: "Concert",
        blurb: "Apple Music big lyrics. The song fills the screen.",
        backdrop: .albumArtBlur(radius: 50, tintBlack: 0.32),
        typography: TypographyStyle(prevSize: 13, currentSize: 36, nextSize: 13,
                                    currentWeight: .bold, italic: false, tracking: -0.6),
        accent: .perTrack(saturationBoost: 0.2),
        layout: .singleWithGhosts,
        glow: GlowSpec(useAccent: true, radius: 12, opacity: 0.4),
        prevNextOpacity: 0.32,
        crossfadeSeconds: 0.32
    )

    static let neon = Theme(
        id: "neon",
        displayName: "Neon",
        blurb: "Dark, italic, with a saturated halo. Synthwave vibe.",
        backdrop: .darkWithAccentGlow,
        typography: TypographyStyle(prevSize: 15, currentSize: 24, nextSize: 15,
                                    currentWeight: .bold, italic: true, tracking: -0.3),
        accent: .perTrack(saturationBoost: 0.4),
        layout: .threeLine,
        glow: GlowSpec(useAccent: true, radius: 22, opacity: 0.85),
        prevNextOpacity: 0.5,
        crossfadeSeconds: 0.26
    )

    static let all: [Theme] = [minimal, crystal, bloom, spotlight, concert, neon]
    static let `default`: Theme = bloom

    static func byId(_ id: String) -> Theme {
        all.first(where: { $0.id == id }) ?? `default`
    }
}
