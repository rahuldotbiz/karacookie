import AppKit
import SwiftUI

@MainActor
final class WelcomeWindowController {
    private var window: NSWindow?

    var hasBeenShown: Bool {
        UserDefaults.standard.bool(forKey: "didShowWelcome")
    }

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let host = NSHostingController(rootView: WelcomeView(onFinish: { [weak self] in
            UserDefaults.standard.set(true, forKey: "didShowWelcome")
            self?.close()
        }))

        let w = NSWindow(contentViewController: host)
        w.title = "Welcome to Karacookie"
        w.styleMask = [.titled, .closable, .fullSizeContentView]
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.isReleasedWhenClosed = false
        w.center()
        w.appearance = NSAppearance(named: .darkAqua)
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = w
    }

    func close() {
        window?.orderOut(nil)
    }
}
