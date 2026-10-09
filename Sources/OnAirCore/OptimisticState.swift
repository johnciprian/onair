import Foundation

/// Shows the state the user just asked for while Zoom catches up. After a successful Mute/Unmute press, Zoom's
/// menu (OnAir's source of truth) keeps the old title for 0.2–1.3 s; waiting for it made the display and flash lag.
/// A stale reading is hidden until Zoom confirms, something else happens, or the timeout passes — after which
/// Zoom's own state is shown again, so a press that silently failed can't leave the display wrong.
public struct OptimisticState {
    public static let timeout: TimeInterval = 2.5

    private var expectation: (target: MicState, from: MicState, deadline: TimeInterval)?

    public init() {}

    public mutating func expect(_ target: MicState, from: MicState, at now: TimeInterval) {
        expectation = (target, from, now + Self.timeout)
    }

    public mutating func resolve(reading: MicState, at now: TimeInterval) -> MicState {
        guard let expectation else { return reading }
        if reading == expectation.from, now < expectation.deadline { return expectation.target }
        self.expectation = nil  // confirmed, superseded by real news, or timed out
        return reading
    }
}
