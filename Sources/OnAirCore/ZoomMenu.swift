/// Interprets Zoom's "Meeting" menu. Zoom shows "Mute audio" while you're live and "Unmute audio" while muted
/// ("… telephone" when joined by phone). With neither, you're not in a call or haven't joined audio.
public enum ZoomMenu {
    static let liveTitles = ["Mute audio", "Mute telephone"]
    static let mutedTitles = ["Unmute audio", "Unmute telephone"]

    public static func state(fromMeetingMenuTitles titles: [String]) -> MicState {
        if titles.contains(where: liveTitles.contains) { return .live }
        if titles.contains(where: mutedTitles.contains) { return .muted }
        return .noMeeting
    }

    /// The item that moves the mic to the wanted state, or nil when it's already there (or there's no meeting).
    /// Targeting a state instead of toggling means a failed or slow press can't leave the mic live after a hold.
    public static func pressTitle(toMute mute: Bool, in titles: [String]) -> String? {
        titles.first { (mute ? liveTitles : mutedTitles).contains($0) }
    }
}
