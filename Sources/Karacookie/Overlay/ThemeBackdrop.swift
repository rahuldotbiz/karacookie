import SwiftUI
import AppKit

struct ThemeBackdrop: View {
    let theme: Theme
    @ObservedObject var stateBox: OverlayStateBox

    var body: some View {
        ZStack {
            switch theme.backdrop {
            case .none:
                Color.clear

            case .glass(let material):
                VisualEffectBackground(material: material.nsMaterial, blendingMode: .behindWindow)

            case .albumArtBlur(let radius, let tintBlack):
                ZStack {
                    Color.black
                    if let art = stateBox.artwork {
                        Image(nsImage: art)
                            .resizable()
                            .scaledToFill()
                            .blur(radius: radius, opaque: true)
                            .saturation(1.3)
                            .opacity(0.85)
                    }
                    Color.black.opacity(tintBlack)
                }

            case .solidDark:
                Color.black.opacity(0.85)

            case .radialLight:
                ZStack {
                    Color.black.opacity(0.92)
                    RadialGradient(
                        colors: [stateBox.accentColor.opacity(0.35), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 240
                    )
                }

            case .darkWithAccentGlow:
                ZStack {
                    Color(red: 0.05, green: 0.05, blue: 0.07).opacity(0.92)
                    RadialGradient(
                        colors: [stateBox.accentColor.opacity(0.55), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 280
                    )
                    .blendMode(.screen)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.easeInOut(duration: theme.crossfadeSeconds), value: stateBox.artwork)
    }
}
