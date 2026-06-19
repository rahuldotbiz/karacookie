import SwiftUI

struct LyricsOverlayView: View {
    @ObservedObject var stateBox: OverlayStateBox
    @ObservedObject var themeStore: ThemeStore
    @AppStorage("opacity") private var opacity: Double = 0.92
    @AppStorage("fontSize") private var userFontDelta: Double = 0   // -4 ... +6
    @AppStorage("popIntensity") private var popIntensity: Double = 0.13

    private var theme: Theme { themeStore.current }

    private var accent: Color {
        switch theme.accent {
        case .fixed(let r, let g, let b):
            return Color(red: r, green: g, blue: b)
        case .perTrack(let satBoost):
            if satBoost == 0 { return stateBox.accentColor }
            return stateBox.accentColor.saturated(by: satBoost)
        }
    }

    var body: some View {
        ZStack {
            ThemeBackdrop(theme: theme, stateBox: stateBox)
                .opacity(opacity)

            content
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(stateBox.isPaused ? 0.55 : 1.0)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(stateBox.accentColor.opacity(0.35), lineWidth: 1.2)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: stateBox.accentColor.opacity(0.28), radius: 30, x: 0, y: 10)
        .shadow(color: .black.opacity(0.50), radius: 40, x: 0, y: 18)
        .frame(minWidth: 380, idealWidth: 580, maxWidth: 1000,
               minHeight: 80, idealHeight: heightForLayout, maxHeight: 360)
        .animation(.easeInOut(duration: theme.crossfadeSeconds), value: lineKey)
        .animation(.easeInOut(duration: 0.5), value: stateBox.accentColor)
        .preferredColorScheme(forcesDarkScheme ? .dark : nil)
    }

    /// Every theme except Minimal/Crystal has an opaque dark backdrop, so
    /// force dark color scheme to keep text white-on-dark regardless of system mode.
    private var forcesDarkScheme: Bool {
        switch theme.backdrop {
        case .none, .glass:                       return false
        case .albumArtBlur, .solidDark,
             .radialLight, .darkWithAccentGlow:   return true
        }
    }

    private var idleTextColor: Color {
        forcesDarkScheme ? Color.white.opacity(0.85) : Color.primary.opacity(0.85)
    }
    private var idleAccentColor: Color {
        forcesDarkScheme ? Color.white.opacity(0.55) : Color.secondary
    }

    private var heightForLayout: CGFloat {
        switch theme.layout {
        case .singleBig:         return 110
        case .singleWithGhosts:  return 180
        case .threeLine:         return 140
        }
    }

    private var lineKey: String {
        switch stateBox.state {
        case .loading: return "loading"
        case .idle(let m): return "i:\(m)"
        case .noLyrics(let t, let a): return "n:\(t)|\(a)"
        case .ad: return "ad"
        case .podcast(let p): return "p:\(p)"
        case .lyrics(let prev, let current, let next):
            return "L:\(prev ?? "")|\(current.text)|\(next ?? "")"
        }
    }

    @ViewBuilder private var content: some View {
        switch stateBox.state {
        case .loading:
            LyricsSkeleton().padding(.horizontal, 6)

        case .idle(let message):
            if message.lowercased().contains("loading") {
                LyricsSkeleton().padding(.horizontal, 6)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "music.note")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(idleAccentColor)
                    Text(message)
                        .font(.system(size: theme.typography.currentSize - 2, weight: .medium))
                        .foregroundStyle(idleTextColor)
                        .multilineTextAlignment(.center)
                }
            }

        case .noLyrics(let track, let artist):
            HStack(spacing: 12) {
                if let art = stateBox.artwork {
                    Image(nsImage: art)
                        .resizable()
                        .interpolation(.medium)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(track).font(.system(size: theme.typography.currentSize, weight: .semibold)).lineLimit(1)
                    Text(artist).font(.system(size: theme.typography.currentSize - 4)).foregroundStyle(.secondary).lineLimit(1)
                    Text("No synced lyrics")
                        .font(.system(size: theme.typography.currentSize - 6))
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
            }

        case .ad:
            Text("Ad break")
                .font(.system(size: theme.typography.currentSize - 2, weight: .medium))
                .foregroundStyle(.secondary)

        case .podcast(let title):
            Text(title)
                .font(.system(size: theme.typography.currentSize - 2))
                .foregroundStyle(.secondary)
                .lineLimit(1)

        case .lyrics(let prev, let current, let next):
            lyricsBody(prev: prev, current: current, next: next)
        }
    }

    @ViewBuilder
    private func lyricsBody(prev: String?, current: CurrentLine, next: String?) -> some View {
        let userDelta = CGFloat(userFontDelta)
        let currentLine = karaokeLineView(current, sizeDelta: userDelta)
        switch theme.layout {
        case .threeLine:
            VStack(spacing: 4) {
                lineText(prev ?? " ", size: theme.typography.prevSize + userDelta).opacity(theme.prevNextOpacity)
                currentLine
                lineText(next ?? " ", size: theme.typography.nextSize + userDelta).opacity(theme.prevNextOpacity)
            }

        case .singleBig:
            currentLine
                .frame(maxWidth: .infinity)

        case .singleWithGhosts:
            VStack(spacing: 6) {
                lineText(prev ?? " ", size: theme.typography.prevSize + userDelta).opacity(theme.prevNextOpacity)
                currentLine
                lineText(next ?? " ", size: theme.typography.nextSize + userDelta).opacity(theme.prevNextOpacity)
            }
        }
    }

    private func lineText(_ s: String, size: CGFloat) -> some View {
        let view = Text(s)
            .font(.system(size: max(8, size), weight: .regular))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .tracking(theme.typography.tracking)
        if theme.typography.italic { return AnyView(view.italic()) }
        return AnyView(view)
    }

    private func karaokeLineView(_ line: CurrentLine, sizeDelta: CGFloat) -> some View {
        KaraokeLineWords(
            words: line.words,
            stateBox: stateBox,
            fontSize: theme.typography.currentSize + sizeDelta,
            weight: theme.typography.currentFontWeight,
            italic: theme.typography.italic,
            tracking: theme.typography.tracking,
            accent: accent,
            glow: theme.glow,
            popIntensity: CGFloat(popIntensity)
        )
    }
}

private struct KaraokeLineWords: View {
    let words: [WordTiming]
    @ObservedObject var stateBox: OverlayStateBox
    let fontSize: CGFloat
    let weight: Font.Weight
    let italic: Bool
    let tracking: CGFloat
    let accent: Color
    let glow: GlowSpec?
    let popIntensity: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                if word.isWhitespace {
                    Text(word.text)
                        .font(.system(size: fontSize, weight: weight))
                } else {
                    WordView(word: word,
                             nowMs: stateBox.nowMs,
                             fontSize: fontSize,
                             weight: weight,
                             italic: italic,
                             tracking: tracking,
                             accent: accent,
                             glow: glow,
                             popIntensity: popIntensity)
                }
            }
        }
        .lineLimit(1)
        .fixedSize()
    }
}

private struct WordView: View {
    let word: WordTiming
    let nowMs: Int
    let fontSize: CGFloat
    let weight: Font.Weight
    let italic: Bool
    let tracking: CGFloat
    let accent: Color
    let glow: GlowSpec?
    let popIntensity: CGFloat

    /// Linear position 0..1 across the word's window (no easing — used for pop scale).
    private var linearProgress: Double {
        let span = max(1, word.endMs - word.startMs)
        let elapsed = max(0, min(span, nowMs - word.startMs))
        return Double(elapsed) / Double(span)
    }

    /// Eased progress 0..1 used to drive the highlight reveal mask.
    private var progress: Double {
        1 - pow(1 - linearProgress, 3)   // easeOutCubic
    }

    /// Bell curve: 1.0 at edges, 1.0 + popIntensity at midpoint of the word.
    private var popScale: CGFloat {
        let p = linearProgress
        guard p > 0, p < 1 else { return 1.0 }
        let bell = 4.0 * p * (1.0 - p)     // 0..1, peaks at 0.5
        return 1.0 + CGFloat(bell) * popIntensity
    }

    var body: some View {
        let base = Text(word.text)
            .font(.system(size: fontSize, weight: weight))
            .tracking(tracking)
        let styled = italic ? AnyView(base.italic()) : AnyView(base)

        return ZStack(alignment: .leading) {
            styled.foregroundStyle(.primary)

            GeometryReader { geo in
                let highlighted = styled
                    .foregroundStyle(accent)
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: geo.size.width * CGFloat(progress))
                    }

                if let glow {
                    highlighted.shadow(color: accent.opacity(glow.opacity), radius: glow.radius)
                } else {
                    highlighted
                }
            }
            .allowsHitTesting(false)
        }
        .fixedSize()
        .scaleEffect(popScale, anchor: .center)
        .animation(.easeOut(duration: 0.08), value: popScale)
    }
}

extension Color {
    func saturated(by delta: Double) -> Color {
        guard delta > 0 else { return self }
        let ns = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor.gray
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ns.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let newS = min(1.0, s + CGFloat(delta))
        return Color(nsColor: NSColor(hue: h, saturation: newS, brightness: b, alpha: a))
    }
}
