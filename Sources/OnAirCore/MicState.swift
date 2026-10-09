/// What OnAir shows. `noPermission` is app-level: without Accessibility access nothing else can be known.
public enum MicState: Equatable, Sendable {
    case notRunning
    case noMeeting
    case muted
    case live
    case noPermission

    /// The hotkey and the badge only act while a mute/unmute choice exists.
    public var isInMeeting: Bool { self == .muted || self == .live }
}
