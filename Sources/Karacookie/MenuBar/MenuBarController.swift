import AppKit

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let permissionStatus: () -> SourceStatus
    private let activeSource: () -> String
    private let onToggle: () -> Void
    private let onClickThrough: () -> Void
    private let onSettings: () -> Void
    private let onGrantAutomation: () -> Void
    private let onQuit: () -> Void

    init(permissionStatus: @escaping () -> SourceStatus,
         activeSource: @escaping () -> String,
         onToggle: @escaping () -> Void,
         onClickThrough: @escaping () -> Void,
         onSettings: @escaping () -> Void,
         onGrantAutomation: @escaping () -> Void,
         onQuit: @escaping () -> Void) {
        self.permissionStatus = permissionStatus
        self.activeSource = activeSource
        self.onToggle = onToggle
        self.onClickThrough = onClickThrough
        self.onSettings = onSettings
        self.onGrantAutomation = onGrantAutomation
        self.onQuit = onQuit
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            let img = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Karacookie")
            img?.isTemplate = true
            button.image = img
            button.imagePosition = .imageLeft
        }
        refresh()
    }

    func refresh() {
        statusItem.menu = buildMenu()
    }

    func setTrack(_ title: String?) {
        guard let button = statusItem.button else { return }
        button.title = title.map { " \(trim($0))" } ?? ""
    }

    private func trim(_ s: String) -> String {
        let max = 38
        if s.count <= max { return s }
        return String(s.prefix(max - 1)) + "…"
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let toggle = NSMenuItem(title: "Toggle Overlay", action: #selector(toggleAction), keyEquivalent: "l")
        toggle.target = self
        toggle.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(toggle)

        let click = NSMenuItem(title: "Toggle Click-Through", action: #selector(clickThroughAction), keyEquivalent: "k")
        click.target = self
        click.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(click)

        menu.addItem(.separator())

        let status = NSMenuItem(title: statusText(), action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)

        if case .noPermission = permissionStatus() {
            let grant = NSMenuItem(title: "Grant Automation Permission…",
                                   action: #selector(grantAction),
                                   keyEquivalent: "")
            grant.target = self
            menu.addItem(grant)
        }

        let settings = NSMenuItem(title: "Settings…", action: #selector(settingsAction), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Karacookie", action: #selector(quitAction), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        return menu
    }

    private func statusText() -> String {
        let src = activeSource()
        let srcSuffix = src.isEmpty ? "" : "  ·  \(src)"
        switch permissionStatus() {
        case .playing:       return "● Playing\(srcSuffix)"
        case .paused:        return "❚❚ Paused\(srcSuffix)"
        case .stopped:       return "■ Stopped\(srcSuffix)"
        case .notRunning:    return "Open Spotify or Apple Music"
        case .noPermission:  return "⚠ Automation permission needed"
        case .error(let m):  return "Error: \(m.prefix(40))"
        case .unknown:       return "Connecting…"
        }
    }

    @objc private func toggleAction() { onToggle() }
    @objc private func clickThroughAction() { onClickThrough() }
    @objc private func settingsAction() { onSettings() }
    @objc private func grantAction() { onGrantAutomation() }
    @objc private func quitAction() { onQuit() }
}
