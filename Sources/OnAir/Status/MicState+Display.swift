import OnAirCore

extension MicState {
    var menuTitle: String {
        switch self {
        case .live: "On Air — your mic is live"
        case .muted: "Off Air — you're muted"
        case .noMeeting: "Not in a meeting"
        case .notRunning: "Zoom isn't open"
        case .noPermission: "Needs Accessibility access"
        }
    }

    var menuSymbol: String {
        switch self {
        case .live: "mic.fill"
        case .muted: "mic.slash.fill"
        case .noMeeting, .notRunning: "mic"
        case .noPermission: "exclamationmark.triangle"
        }
    }
}
