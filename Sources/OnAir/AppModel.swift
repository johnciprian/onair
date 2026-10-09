import AppKit
import OnAirCore

/// Owns every piece of the app and wires them together. Displays read `monitor.state` themselves;
/// `render()` re-applies preferences whenever the state or a setting changes.
@MainActor
final class AppModel {
    let prefs = Preferences()
    let monitor: StatusMonitor
    private let zoom: ZoomController
    private var menuBar: MenuBarController?

    init() {
        let zoom = ZoomController()
        self.zoom = zoom
        monitor = StatusMonitor(read: DemoMode.isOn ? DemoMode.read : zoom.readState)
    }

    func start() {
        // Demo runs as a regular app so screenshot tooling can find (and be granted) it during visual checks.
        if DemoMode.isOn { NSApp.setActivationPolicy(.regular) }
        menuBar = MenuBarController(app: self)
        monitor.onChange = { [weak self] _ in self?.render() }
        render()
    }

    func render() {
        menuBar?.update()
    }

    func requestAccessibility() {
        // Shows the system prompt and adds OnAir to the Accessibility list in System Settings.
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }
}
