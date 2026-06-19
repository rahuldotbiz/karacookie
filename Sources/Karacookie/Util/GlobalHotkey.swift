import AppKit
import Carbon.HIToolbox

/// Minimal Carbon-based global hotkey wrapper. Works without Accessibility permission.
@MainActor
final class GlobalHotkey {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let id: UInt32

    nonisolated(unsafe) private static var registry: [UInt32: () -> Void] = [:]
    nonisolated(unsafe) private static var nextID: UInt32 = 1
    nonisolated(unsafe) private static var sharedHandlerInstalled = false

    init() {
        self.id = GlobalHotkey.nextID
        GlobalHotkey.nextID += 1
    }

    func register(keyCode: Int, modifiers: UInt32, handler: @escaping () -> Void) {
        GlobalHotkey.registry[id] = handler
        Self.ensureHandlerInstalled()

        let signature: OSType = 0x4B424152 // 'KBAR'
        let hkID = EventHotKeyID(signature: signature, id: id)
        RegisterEventHotKey(UInt32(keyCode),
                            modifiers,
                            hkID,
                            GetEventDispatcherTarget(),
                            0,
                            &hotKeyRef)
    }

    func unregister() {
        GlobalHotkey.registry[id] = nil
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    private static func ensureHandlerInstalled() {
        guard !sharedHandlerInstalled else { return }
        sharedHandlerInstalled = true

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        var handler: EventHandlerRef?
        InstallEventHandler(GetEventDispatcherTarget(), { _, eventRef, _ in
            var hkID = EventHotKeyID()
            GetEventParameter(eventRef,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout<EventHotKeyID>.size,
                              nil,
                              &hkID)
            let captured = hkID.id
            DispatchQueue.main.async {
                GlobalHotkey.registry[captured]?()
            }
            return noErr
        }, 1, &spec, nil, &handler)
    }
}

enum HotkeyCodes {
    static let l: Int = kVK_ANSI_L
    static let k: Int = kVK_ANSI_K
    static let cmdOpt: UInt32 = UInt32(cmdKey) | UInt32(optionKey)
}
