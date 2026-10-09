/// Holds the last known state through brief read failures (Zoom busy, e.g. while starting a screen share),
/// so the display doesn't flash "not in a meeting" while the mic is live. Persistent failure gives up.
public struct StickyState {
    /// At the 0.5 s poll, about 2 s of unanswered reads.
    public static let maxMisses = 4

    public private(set) var state: MicState
    private var misses = 0

    public init(_ initial: MicState) {
        state = initial
    }

    /// `reading` is nil when Zoom didn't answer.
    public mutating func update(with reading: MicState?) -> MicState {
        if let reading {
            misses = 0
            state = reading
        } else {
            misses += 1
            if misses > Self.maxMisses { state = .noMeeting }
        }
        return state
    }
}
