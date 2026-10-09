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
    let hotkey = Hotkey()
    private(set) var hotkeyAvailable = true
    private var press = PressLogic()
    private let recorder = HotkeyRecorder()

    init() {
        let zoom = ZoomController()
        self.zoom = zoom
        monitor = StatusMonitor(read: DemoMode.isOn ? DemoMode.read : zoom.readState)
    }

    func start() {
        // Demo runs as a regular app so screenshot tooling can find (and be granted) it during visual checks.
        if DemoMode.isOn { NSApp.setActivationPolicy(.regular) }
        menuBar = MenuBarController(app: self)
        hotkey.onPress = { [weak self] in self?.keyDown() }
        hotkey.onRelease = { [weak self] in self?.keyUp() }
        registerHotkey()
        monitor.onChange = { [weak self] _ in self?.render() }
        render()
    }

    func render() {
        menuBar?.update()
    }

    func registerHotkey() {
        guard let combo = prefs.hotkey else {
            hotkey.unregister()
            hotkeyAvailable = true
            return
        }
        hotkeyAvailable = hotkey.register(combo)
    }

    func recordHotkey() {
        // Carbon swallows a registered combo before any window sees it, so release ours while recording.
        hotkey.unregister()
        recorder.show(current: prefs.hotkey) { [weak self] combo in
            guard let self else { return }
            if let combo { prefs.hotkey = combo }
            registerHotkey()
        }
    }

    private func keyDown() {
        if press.press(at: ProcessInfo.processInfo.systemUptime, inMeeting: monitor.state.isInMeeting) { toggleZoom() }
    }

    private func keyUp() {
        if press.release(at: ProcessInfo.processInfo.systemUptime) { toggleZoom() }
    }

    private func toggleZoom() {
        let old = monitor.state
        guard zoom.toggle() else { return }
        monitor.refreshAfterToggle(from: old) { _ in }
    }

    func requestAccessibility() {
        // Shows the system prompt and adds OnAir to the Accessibility list in System Settings.
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }
}
