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

    /// The line under the big status sign in the menu bar panel.
    var panelSubtitle: String {
        switch self {
        case .live: "Your mic is live"
        case .muted: "You're muted"
        case .noMeeting: "Not in a meeting"
        case .notRunning: "Zoom isn't open"
        case .noPermission: "OnAir needs Accessibility access to read Zoom"
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
