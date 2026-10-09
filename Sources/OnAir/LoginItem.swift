import ServiceManagement

/// Launch at login through the system's Login Items (no helper app needed).
enum LoginItem {
    static var isEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            // If registration fails (e.g. running from build/ rather than /Applications) the box simply stays unticked.
            if newValue { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
        }
    }
}
