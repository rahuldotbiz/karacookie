import SwiftUI

struct WelcomeView: View {
    let onFinish: () -> Void
    @AppStorage("theme") private var themeId: String = ThemePresets.default.id

    var body: some View {
        ZStack {
            // Subtle gradient backdrop with a soft halo.
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.06, blue: 0.18),
                    Color(red: 0.04, green: 0.04, blue: 0.08)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(red: 1.0, green: 0.5, blue: 0.36).opacity(0.35), .clear],
                center: .topLeading, startRadius: 20, endRadius: 380
            )
            .blendMode(.screen)
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    steps
                    themeSection
                    Spacer(minLength: 4)
                    finishButton
                }
                .padding(28)
            }
        }
        .frame(width: 620, height: 660)
        .foregroundStyle(.white)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "music.note")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.6, blue: 0.4))
                Text("Karacookie")
                    .font(.system(size: 28, weight: .bold))
            }
            Text("Lyrics that move with the music.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How it works")
                .font(.system(size: 16, weight: .semibold))
                .padding(.bottom, 2)

            StepRow(number: 1,
                    icon: "play.circle.fill",
                    title: "Play a song",
                    detail: "Open Spotify or the Music app and hit play.")
            StepRow(number: 2,
                    icon: "lock.shield.fill",
                    title: "Allow Karacookie once",
                    detail: "macOS will ask: \"Karacookie wants to control Spotify\". Click OK.")
            StepRow(number: 3,
                    icon: "sparkles",
                    title: "Lyrics float on top",
                    detail: "Karacookie pins a translucent bar above every app. Drag it where you want.")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick your look")
                .font(.system(size: 16, weight: .semibold))
            Text("Change anytime in Settings.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
            ThemePicker()
                .preferredColorScheme(.dark)
                .tint(Color(red: 1.0, green: 0.6, blue: 0.4))
        }
    }

    private var finishButton: some View {
        HStack {
            Spacer()
            Button("Get started") { onFinish() }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 1.0, green: 0.5, blue: 0.36))
        }
    }
}

private struct StepRow: View {
    let number: Int
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.5, blue: 0.36).opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 1.0, green: 0.7, blue: 0.5))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(detail).font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
