import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("opacity") private var opacity: Double = 0.92
    @AppStorage("fontSize") private var fontDelta: Double = 0
    @AppStorage("popIntensity") private var popIntensity: Double = 0.13
    @AppStorage("lockPosition") private var lockPosition: Bool = false
    @AppStorage("hideWhenPaused") private var hideWhenPaused: Bool = false
    @AppStorage("showTrackInMenuBar") private var showTrackInMenuBar: Bool = true
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ThemePicker()

                section(header: "Energy") {
                    HStack {
                        Text("Word bounce")
                        Spacer()
                        Picker("", selection: $popIntensity) {
                            Text("Off").tag(0.0)
                            Text("Subtle").tag(0.06)
                            Text("Medium").tag(0.13)
                            Text("Punchy").tag(0.22)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 280)
                        .labelsHidden()
                    }
                }

                section(header: "Overlay") {
                    HStack {
                        Text("Opacity")
                        Slider(value: $opacity, in: 0.4...1.0)
                        Text(String(format: "%.0f%%", opacity * 100))
                            .monospacedDigit()
                            .frame(width: 44, alignment: .trailing)
                    }
                    HStack {
                        Text("Font size")
                        Slider(value: $fontDelta, in: -4...6, step: 1)
                        Text("\(Int(fontDelta) >= 0 ? "+" : "")\(Int(fontDelta))pt")
                            .monospacedDigit()
                            .frame(width: 56, alignment: .trailing)
                    }
                    Toggle("Lock position (prevent dragging)", isOn: $lockPosition)
                    Toggle("Hide overlay when paused", isOn: $hideWhenPaused)
                }

                section(header: "Source") {
                    SourcePickerView()
                    Text("On first use of each app, macOS will ask you to allow Karacookie to control it — click OK.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Open Automation Settings…") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }

                section(header: "Menu bar") {
                    Toggle("Show current track in menu bar", isOn: $showTrackInMenuBar)
                }

                section(header: "System") {
                    Toggle("Launch at login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, newValue in
                            do {
                                if newValue { try SMAppService.mainApp.register() }
                                else { try SMAppService.mainApp.unregister() }
                            } catch {
                                NSLog("Launch-at-login toggle failed: \(error)")
                            }
                        }
                    LabeledContent("Toggle overlay") { Text("⌥⌘L").monospaced() }
                    LabeledContent("Click-through") { Text("⌥⌘K").monospaced() }
                }
            }
            .padding(20)
        }
        .frame(width: 580, height: 720)
    }

    @ViewBuilder
    private func section<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header).font(.headline)
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
        }
    }
}
