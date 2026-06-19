import SwiftUI

struct ThemePicker: View {
    @AppStorage("theme") private var themeId: String = ThemePresets.default.id

    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 14)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Theme")
                .font(.headline)
            Text("Pick how immersive you want lyrics to feel. You can change this anytime.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(ThemePresets.all) { theme in
                    ThemeCard(theme: theme, selected: themeId == theme.id)
                        .onTapGesture { themeId = theme.id }
                }
            }
            .padding(.top, 4)
        }
    }
}

private struct ThemeCard: View {
    let theme: Theme
    let selected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ThemeThumbnail(theme: theme)
                .frame(height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(selected ? Color.accentColor : Color.white.opacity(0.08),
                                lineWidth: selected ? 2.5 : 1)
                )

            HStack(spacing: 4) {
                Text(theme.displayName).font(.system(size: 13, weight: .semibold))
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.system(size: 12))
                }
                Spacer(minLength: 0)
            }
            Text(theme.blurb)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(selected ? 0.06 : 0.025))
        )
        .contentShape(Rectangle())
    }
}

private struct ThemeThumbnail: View {
    let theme: Theme

    private let stubPrev    = "yesterday all my troubles…"
    private let stubCurrent = "now it looks as though"
    private let stubNext    = "oh, I believe in yesterday"
    private let stubAccent  = Color(red: 0.42, green: 0.62, blue: 1.0) // demo blue-ish

    var body: some View {
        ZStack {
            backdrop
            lyricsPreview
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        }
    }

    @ViewBuilder private var backdrop: some View {
        switch theme.backdrop {
        case .none:
            Color.black.opacity(0.18)
        case .glass:
            ZStack {
                LinearGradient(colors: [.gray.opacity(0.35), .gray.opacity(0.18)],
                               startPoint: .top, endPoint: .bottom)
                Rectangle().fill(.ultraThinMaterial)
            }
        case .albumArtBlur(_, let tint):
            ZStack {
                LinearGradient(colors: [stubAccent.opacity(0.7), .pink.opacity(0.55), .black],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Color.black.opacity(tint)
            }
        case .solidDark:
            Color.black.opacity(0.85)
        case .radialLight:
            ZStack {
                Color.black
                RadialGradient(colors: [stubAccent.opacity(0.35), .clear],
                               center: .center, startRadius: 0, endRadius: 80)
            }
        case .darkWithAccentGlow:
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07)
                RadialGradient(colors: [stubAccent.opacity(0.7), .clear],
                               center: .center, startRadius: 6, endRadius: 90)
                    .blendMode(.screen)
            }
        }
    }

    @ViewBuilder private var lyricsPreview: some View {
        let accent = stubAccent
        switch theme.layout {
        case .threeLine:
            VStack(spacing: 2) {
                Text(stubPrev).font(.system(size: 8)).foregroundStyle(.white.opacity(theme.prevNextOpacity * 0.9)).lineLimit(1)
                wipedLine(stubCurrent, size: 11, accent: accent)
                Text(stubNext).font(.system(size: 8)).foregroundStyle(.white.opacity(theme.prevNextOpacity * 0.9)).lineLimit(1)
            }
        case .singleBig:
            wipedLine(stubCurrent, size: 14, accent: accent)
        case .singleWithGhosts:
            VStack(spacing: 3) {
                Text(stubPrev).font(.system(size: 7)).foregroundStyle(.white.opacity(0.35)).lineLimit(1)
                wipedLine(stubCurrent, size: 14, accent: accent)
                Text(stubNext).font(.system(size: 7)).foregroundStyle(.white.opacity(0.35)).lineLimit(1)
            }
        }
    }

    private func wipedLine(_ s: String, size: CGFloat, accent: Color) -> some View {
        ZStack(alignment: .leading) {
            Text(s)
                .font(.system(size: size, weight: theme.typography.currentFontWeight))
                .italic(theme.typography.italic)
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
            GeometryReader { geo in
                Text(s)
                    .font(.system(size: size, weight: theme.typography.currentFontWeight))
                    .italic(theme.typography.italic)
                    .foregroundStyle(accent)
                    .lineLimit(1)
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: geo.size.width * 0.42)
                    }
                    .shadow(color: theme.glow != nil ? accent.opacity(theme.glow!.opacity) : .clear,
                            radius: theme.glow?.radius ?? 0)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private extension Text {
    @ViewBuilder
    func italic(_ enabled: Bool) -> some View {
        if enabled { self.italic() } else { self }
    }
}
