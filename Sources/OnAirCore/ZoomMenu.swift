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

    /// The item to press to flip the mic, if Zoom is showing one.
    public static func toggleTitle(in titles: [String]) -> String? {
        titles.first { liveTitles.contains($0) || mutedTitles.contains($0) }
    }
}
