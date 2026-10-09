import ServiceManagement

/// Launch at login through the system's Login Items (no helper app needed).
enum LoginItem {
    /// "Requires approval" counts as on: OnAir is registered and only waiting for the user to allow it in
    /// System Settings. Reading it as off would untick the box, which unregisters it again.
    static var isEnabled: Bool {
        get { [.enabled, .requiresApproval].contains(SMAppService.mainApp.status) }
        set {
            // If registration fails (e.g. running from build/ rather than /Applications) the box simply stays unticked.
            if newValue { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
            if SMAppService.mainApp.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
        }
    }
}
