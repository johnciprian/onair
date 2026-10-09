import Foundation

/// Turns hotkey press/release into toggles: the press always toggles (so a tap feels instant), and a release
/// after a hold toggles back — push-to-talk when muted, a momentary mute when live.
public struct PressLogic {
    public static let holdThreshold: TimeInterval = 0.3

    private var pressedAt: TimeInterval?
    private var toggledOnPress = false

    public init() {}

    /// Returns true when Zoom should be toggled now.
    public mutating func press(at time: TimeInterval, inMeeting: Bool) -> Bool {
        // Auto-repeat sends more presses while the key is held; only the first one counts.
        guard pressedAt == nil else { return false }
        pressedAt = time
        toggledOnPress = inMeeting
        return inMeeting
    }

    /// Forgets a press whose release will never come (the Mac slept mid-hold, or the hotkey changed),
    /// so the next press isn't mistaken for auto-repeat and ignored forever.
    public mutating func cancel() {
        pressedAt = nil
        toggledOnPress = false
    }

    /// Returns true when Zoom should be toggled back (the key was held, and the press did toggle).
    public mutating func release(at time: TimeInterval) -> Bool {
        defer { pressedAt = nil; toggledOnPress = false }
        guard let pressedAt, toggledOnPress else { return false }
        return time - pressedAt >= Self.holdThreshold
    }
}
