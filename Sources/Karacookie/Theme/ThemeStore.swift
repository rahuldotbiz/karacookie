import SwiftUI
import Combine

@MainActor
final class ThemeStore: ObservableObject {
    @Published private(set) var current: Theme = ThemePresets.default

    private let key = "theme"
    private var observerTask: Task<Void, Never>?

    init() {
        let id = UserDefaults.standard.string(forKey: key) ?? ThemePresets.default.id
        current = ThemePresets.byId(id)

        // React to UserDefaults changes from the ThemePicker.
        observerTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UserDefaults.didChangeNotification) {
                guard let self else { return }
                let id = UserDefaults.standard.string(forKey: self.key) ?? ThemePresets.default.id
                let next = ThemePresets.byId(id)
                if next != self.current { self.current = next }
            }
        }
    }

    deinit { observerTask?.cancel() }
}
