import AppKit
import Carbon.HIToolbox

/// Whether Zoom's own Mute/Unmute shortcut is the same combo as OnAir's. If it is, Zoom grabs the key press
/// first and OnAir never sees it (no push-to-talk, no flash) — so OnAir must say so rather than look fine.
public enum ZoomShortcut {
    /// Zoom stores its shortcut as a key code plus NSEvent modifier flags (including fn); it only stores one
    /// once the user has changed it, so a missing value means Zoom's default, ⌘⇧A.
    /// A cleared shortcut is stored as key code -1. The file belongs to Zoom, so anything out of range is treated
    /// as "no shortcut" rather than trusted (converting -1 straight to an unsigned value crashed OnAir).
    public static func conflicts(zoomKeyCode: Int?, zoomModifiers: Int?, with combo: KeyCombo) -> Bool {
        guard let keyCode = UInt16(exactly: zoomKeyCode ?? kVK_ANSI_A),
              let rawModifiers = UInt(exactly: zoomModifiers ?? Int(NSEvent.ModifierFlags([.command, .shift]).rawValue))
        else { return false }
        let modifiers = NSEvent.ModifierFlags(rawValue: rawModifiers)
        return keyCode == combo.keyCode
            && modifiers.intersection([.control, .option, .shift, .command]) == combo.modifierFlags
    }
}
