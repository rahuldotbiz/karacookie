import SwiftUI
import AppKit

struct Theme: Identifiable, Equatable {
    let id: String
    let displayName: String
    let blurb: String

    let backdrop: BackdropStyle
    let typography: TypographyStyle
    let accent: AccentMode
    let layout: LineLayout
    let glow: GlowSpec?
    let prevNextOpacity: Double
    let crossfadeSeconds: Double

    static func == (lhs: Theme, rhs: Theme) -> Bool { lhs.id == rhs.id }
}

enum BackdropStyle: Equatable {
    case none
    case glass(GlassMaterial)
    case albumArtBlur(radius: CGFloat, tintBlack: Double)   // tintBlack 0..1
    case solidDark
    case radialLight                                         // dark base + light pool in middle
    case darkWithAccentGlow                                  // dark base + dominant-color halo
}

enum GlassMaterial: Equatable {
    case hud, sidebar, popover, ultraThin

    var nsMaterial: NSVisualEffectView.Material {
        switch self {
        case .hud:       return .hudWindow
        case .sidebar:   return .sidebar
        case .popover:   return .popover
        case .ultraThin: return .underWindowBackground
        }
    }
}

struct TypographyStyle: Equatable {
    let prevSize: CGFloat
    let currentSize: CGFloat
    let nextSize: CGFloat
    let currentWeight: NSFont.Weight
    let italic: Bool
    let tracking: CGFloat   // letter-spacing in points
}

extension TypographyStyle {
    var currentFontWeight: Font.Weight {
        switch currentWeight {
        case .ultraLight: return .ultraLight
        case .thin:       return .thin
        case .light:      return .light
        case .regular:    return .regular
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        case .black:      return .black
        default:          return .semibold
        }
    }
}

enum AccentMode: Equatable {
    case fixed(red: Double, green: Double, blue: Double)
    case perTrack(saturationBoost: Double)
}

enum LineLayout: Equatable {
    case threeLine          // prev / current / next
    case singleBig          // just current
    case singleWithGhosts   // current big + prev/next as tiny ghosts
}

struct GlowSpec: Equatable {
    let useAccent: Bool
    let radius: CGFloat
    let opacity: Double
}
