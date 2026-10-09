import Carbon.HIToolbox
import OnAirCore

/// A global hotkey via Carbon's RegisterEventHotKey: it reports both press and release (push-to-talk needs
/// the release) and, unlike a keyboard event tap, needs no Input Monitoring permission.
@MainActor
final class Hotkey {
    var onPress: () -> Void = {}
    var onRelease: () -> Void = {}
    private var hotKeyRef: EventHotKeyRef?

    init() {
        var events = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased)),
        ]
        // `self` is passed as an unretained pointer; AppModel keeps this Hotkey alive for the app's lifetime.
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            let hotkey = Unmanaged<Hotkey>.fromOpaque(userData!).takeUnretainedValue()
            let pressed = GetEventKind(event) == UInt32(kEventHotKeyPressed)
            MainActor.assumeIsolated { pressed ? hotkey.onPress() : hotkey.onRelease() }
            return noErr
        }, events.count, &events, Unmanaged.passUnretained(self).toOpaque(), nil)
    }

    /// Returns false when another app already owns the combo.
    func register(_ combo: KeyCombo) -> Bool {
        unregister()
        let id = EventHotKeyID(signature: OSType(0x4F4E_4152), id: 1)  // 'ONAR'
        return RegisterEventHotKey(UInt32(combo.keyCode), combo.carbonModifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef) == noErr
    }

    func unregister() {
        guard let hotKeyRef else { return }
        UnregisterEventHotKey(hotKeyRef)
        self.hotKeyRef = nil
    }
}
