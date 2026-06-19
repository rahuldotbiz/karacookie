import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController!
    private var panel: FloatingPanel!
    private let stateBox = OverlayStateBox()
    private let themeStore = ThemeStore()
    private let sources = SourceManager()
    private var engine: PlaybackEngine!
    private let settingsWindow = SettingsWindowController()
    private let welcomeWindow = WelcomeWindowController()
    private let toggleHotkey = GlobalHotkey()
    private let clickThroughHotkey = GlobalHotkey()
    private var statusCancellable: AnyCancellable?
    private var nowPlayingCancellable: AnyCancellable?
    private var prefCancellable: AnyCancellable?
    private var pauseCancellable: AnyCancellable?
    private var hideTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        engine = PlaybackEngine(
            sources: sources,
            lyricsService: LyricsService(),
            stateBox: stateBox
        )

        menuBar = MenuBarController(
            permissionStatus: { [weak self] in self?.sources.status ?? .unknown },
            activeSource: { [weak self] in self?.sources.activeSourceName ?? "" },
            onToggle: { [weak self] in self?.togglePanel() },
            onClickThrough: { [weak self] in self?.toggleClickThrough() },
            onSettings: { [weak self] in self?.settingsWindow.show() },
            onGrantAutomation: { [weak self] in self?.sources.openAutomationSettings() },
            onQuit: { NSApp.terminate(nil) }
        )

        let view = LyricsOverlayView(stateBox: stateBox, themeStore: themeStore)
        let initial = NSRect(x: 200, y: 200, width: 580, height: 130)
        panel = FloatingPanel(contentRect: initial)
        panel.contentView = NSHostingView(rootView: view)
        panel.orderFrontRegardless()
        applyLockPosition()

        toggleHotkey.register(keyCode: HotkeyCodes.l, modifiers: HotkeyCodes.cmdOpt) { [weak self] in
            self?.togglePanel()
        }
        clickThroughHotkey.register(keyCode: HotkeyCodes.k, modifiers: HotkeyCodes.cmdOpt) { [weak self] in
            self?.toggleClickThrough()
        }

        statusCancellable = sources.$status
            .removeDuplicates()
            .sink { [weak self] _ in self?.menuBar.refresh() }

        nowPlayingCancellable = sources.$nowPlaying
            .removeDuplicates(by: { $0?.track?.id == $1?.track?.id })
            .sink { [weak self] np in self?.updateMenuBarTrack(np) }

        pauseCancellable = stateBox.$isPaused
            .removeDuplicates()
            .sink { [weak self] paused in self?.handlePauseChange(paused) }

        prefCancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.applyLockPosition()
                self?.applyMenuBarTrackVisibility()
            }

        stateBox.state = .idle(message: "Open Spotify or Apple Music and press Play")
        engine.start()
        sources.start()

        if !welcomeWindow.hasBeenShown {
            welcomeWindow.show()
        }
    }

    private func togglePanel() {
        if panel.isVisible { panel.orderOut(nil) } else { panel.orderFrontRegardless() }
    }

    private func toggleClickThrough() {
        panel.ignoresMouseEvents.toggle()
    }

    private func applyLockPosition() {
        let locked = UserDefaults.standard.bool(forKey: "lockPosition")
        panel.isMovableByWindowBackground = !locked
        panel.isMovable = !locked
    }

    private func handlePauseChange(_ paused: Bool) {
        let hideWhenPaused = UserDefaults.standard.bool(forKey: "hideWhenPaused")
        hideTimer?.invalidate()
        if paused, hideWhenPaused {
            hideTimer = Timer.scheduledTimer(withTimeInterval: 12.0, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in self?.panel.orderOut(nil) }
            }
        } else if !paused {
            if !panel.isVisible { panel.orderFrontRegardless() }
        }
    }

    private func updateMenuBarTrack(_ np: NowPlaying?) {
        applyMenuBarTrackVisibility(np: np)
    }

    private func applyMenuBarTrackVisibility(np maybeNp: NowPlaying? = nil) {
        let show = UserDefaults.standard.object(forKey: "showTrackInMenuBar") as? Bool ?? true
        let np = maybeNp ?? sources.nowPlaying
        if show, let t = np?.track, np?.isPlaying == true {
            menuBar.setTrack("\(t.name) — \(t.artist)")
        } else {
            menuBar.setTrack(nil)
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == "karacookie" {
            NSLog("Direct URL open: \(url)")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        sources.stop()
        engine.stop()
        toggleHotkey.unregister()
        clickThroughHotkey.unregister()
    }
}
