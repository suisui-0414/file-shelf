import Carbon.HIToolbox
import AppKit

// Carbon の RegisterEventHotKey はアクセシビリティ権限なしで
// アプリがフォーカスを持たない状態でもグローバルに動作する
final class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var callback: (() -> Void)?

    private init() {}

    func register(keyCode: UInt32, carbonModifiers: UInt32, callback: @escaping () -> Void) {
        unregister()
        self.callback = callback

        if eventHandlerRef == nil {
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
            InstallEventHandler(
                GetApplicationEventTarget(),
                { _, _, userData -> OSStatus in
                    guard let userData else { return noErr }
                    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                    manager.callback?()
                    return noErr
                },
                1,
                &eventType,
                Unmanaged.passUnretained(self).toOpaque(),
                &eventHandlerRef
            )
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x46534846), id: 1) // 'FSHF'
        RegisterEventHotKey(keyCode, carbonModifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    static func carbonModifiers(from nsModifiers: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if nsModifiers.contains(.command) { carbon |= UInt32(cmdKey) }
        if nsModifiers.contains(.option)  { carbon |= UInt32(optionKey) }
        if nsModifiers.contains(.control) { carbon |= UInt32(controlKey) }
        if nsModifiers.contains(.shift)   { carbon |= UInt32(shiftKey) }
        return carbon
    }
}
