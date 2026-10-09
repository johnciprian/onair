import AppKit
import Carbon.HIToolbox

/// A recorded global shortcut. The key's label is stored with the code so the menu can show it
/// without keyboard-layout lookups.
public struct KeyCombo: Codable, Equatable, Sendable {
    public let keyCode: UInt16
    /// `NSEvent.ModifierFlags` raw value, limited to ⌃⌥⇧⌘.
    public let modifiers: UInt
    public let keyLabel: String

    static let allowedModifiers: NSEvent.ModifierFlags = [.control, .option, .shift, .command]

    /// Keys no app uses for typing, so they're safe as a hotkey on their own.
    static let bareKeys: Set<Int> = [kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17, kVK_F18, kVK_F19, kVK_F20]

    static let specialLabels: [Int: String] = [
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5",
        kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10",
        kVK_F11: "F11", kVK_F12: "F12", kVK_F13: "F13", kVK_F14: "F14", kVK_F15: "F15",
        kVK_F16: "F16", kVK_F17: "F17", kVK_F18: "F18", kVK_F19: "F19", kVK_F20: "F20",
        kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
    ]

    /// Returns nil for combos that would hijack normal typing everywhere: a bare key, ⇧ + key, or ⌥ + key
    /// (⌥ types characters like µ and é). So ⌃ or ⌘ is required — except for F13–F20, which nothing types with.
    public init?(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags, characters: String?) {
        let mods = modifierFlags.intersection(Self.allowedModifiers)
        guard Self.bareKeys.contains(Int(keyCode)) || !mods.isDisjoint(with: [.control, .command]) else { return nil }
        self.keyCode = keyCode
        self.modifiers = mods.rawValue
        self.keyLabel = Self.label(forKeyCode: keyCode, characters: characters)
    }

    public var modifierFlags: NSEvent.ModifierFlags { NSEvent.ModifierFlags(rawValue: modifiers) }

    /// The modifier mask `RegisterEventHotKey` expects.
    public var carbonModifiers: UInt32 {
        var result = 0
        if modifierFlags.contains(.control) { result |= controlKey }
        if modifierFlags.contains(.option) { result |= optionKey }
        if modifierFlags.contains(.shift) { result |= shiftKey }
        if modifierFlags.contains(.command) { result |= cmdKey }
        return UInt32(result)
    }

    static let menuKeyCharacters: [Int: Int] = {
        let fKeys = [kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9, kVK_F10,
                     kVK_F11, kVK_F12, kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17, kVK_F18, kVK_F19, kVK_F20]
        var map = Dictionary(uniqueKeysWithValues: fKeys.enumerated().map { ($1, NSF1FunctionKey + $0) })
        map[kVK_Space] = 0x20
        map[kVK_Return] = 0x0D
        map[kVK_Tab] = 0x09
        map[kVK_Delete] = 0x08
        map[kVK_ForwardDelete] = NSDeleteFunctionKey
        map[kVK_LeftArrow] = NSLeftArrowFunctionKey
        map[kVK_RightArrow] = NSRightArrowFunctionKey
        map[kVK_UpArrow] = NSUpArrowFunctionKey
        map[kVK_DownArrow] = NSDownArrowFunctionKey
        map[kVK_Home] = NSHomeFunctionKey
        map[kVK_End] = NSEndFunctionKey
        map[kVK_PageUp] = NSPageUpFunctionKey
        map[kVK_PageDown] = NSPageDownFunctionKey
        return map
    }()

    /// The character `NSMenuItem.keyEquivalent` needs so a menu can show this shortcut natively,
    /// or nil for a key with no menu form (the menu then shows no shortcut rather than a wrong one).
    public var menuKeyEquivalent: String? {
        if let code = Self.menuKeyCharacters[Int(keyCode)], let scalar = UnicodeScalar(code) { return String(scalar) }
        return keyLabel.count == 1 ? keyLabel.lowercased() : nil
    }

    public var keycaps: [String] { Self.symbols(for: modifierFlags) + [keyLabel] }

    public var displayString: String { keycaps.joined() }

    /// Modifier symbols in Apple's standard order.
    public static func symbols(for flags: NSEvent.ModifierFlags) -> [String] {
        let ordered: [(NSEvent.ModifierFlags, String)] = [(.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
        return ordered.filter { flags.contains($0.0) }.map(\.1)
    }

    public static func label(forKeyCode keyCode: UInt16, characters: String?) -> String {
        if let special = specialLabels[Int(keyCode)] { return special }
        if let characters, !characters.isEmpty { return characters.uppercased() }
        return "Key \(keyCode)"
    }
}
