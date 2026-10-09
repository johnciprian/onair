import OnAirCore

extension MicState {
    /// Spoken by VoiceOver for the menu bar item.
    var menuTitle: String {
        switch self {
        case .live: "On Air — your mic is live"
        case .muted: "Off Air — you're muted"
        case .noMeeting: "Not in a meeting"
        case .notRunning: "Zoom isn't open"
        case .noPermission: "Needs Accessibility access"
        }
    }

    /// The status row at the top of the menu.
    var statusTitle: String {
        switch self {
        case .live: "Microphone Live"
        case .muted: "Microphone Muted"
        case .noMeeting: "Not in a Meeting"
        case .notRunning: "Zoom Isn't Open"
        case .noPermission: "Needs Accessibility Access"
        }
    }

    var statusDetail: String {
        switch self {
        case .live, .muted, .noMeeting: "Zoom"
        case .notRunning: "Open Zoom to see your mic status"
        case .noPermission: "OnAir can't read Zoom yet"
        }
    }
}
