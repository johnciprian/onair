import AppKit
import OnAirCore
import os

/// Owns every piece of the app and wires them together. Displays read `monitor.state` themselves;
/// `render()` re-applies preferences whenever the state or a setting changes.
@MainActor
final class AppModel {
    let prefs = Preferences()
    let monitor: StatusMonitor
    private let zoom: ZoomController
    private var menuBar: MenuBarController?
    private var badge: BadgeWindow?
    private var glow: GlowWindows?
    let hotkey = Hotkey()
    private(set) var hotkeyAvailable = true
    private var press = PressLogic()
    /// The state when the current key press began. A hold returns Zoom to exactly this rather than toggling
    /// whatever is showing, so a failed or slow press can't leave the mic live after push-to-talk.
    private var stateAtPress = MicState.noMeeting
    private let recorder = HotkeyRecorder()
    private let flash = FlashWindow()
    private let log = Logger(subsystem: "com.johnciprian.OnAir", category: "hotkey")
    private lazy var onboarding = OnboardingWindow(app: self)

    init() {
        let zoom = ZoomController()
        self.zoom = zoom
        let read: () -> MicState? = DemoMode.isOn ? DemoMode.read : zoom.readState
        monitor = StatusMonitor(read: read)
    }

    func start() {
        // Demo runs as a regular app so screenshot tooling can find (and be granted) it during visual checks.
        if DemoMode.isOn { NSApp.setActivationPolicy(.regular) }
        menuBar = MenuBarController(app: self)
        badge = BadgeWindow(monitor: monitor, prefs: prefs)
        glow = GlowWindows(monitor: monitor)
        hotkey.onPress = { [weak self] in self?.keyDown() }
        hotkey.onRelease = { [weak self] in self?.keyUp() }
        registerHotkey()
        // A hold interrupted by sleep never gets its key-up; forget it so the hotkey keeps working.
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.press.cancel() }
        }
        monitor.onChange = { [weak self] _ in self?.render() }
        render()
        if !prefs.hasCompletedOnboarding { onboarding.show() }
    }

    func render() {
        menuBar?.update()
        badge?.update(enabled: prefs.showBadge)
        glow?.setEnabled(prefs.showGlow)
    }

    /// Read fresh each time: the user may change Zoom's shortcut while OnAir is running.
    var hotkeyConflictsWithZoom: Bool {
        prefs.hotkey.map(zoom.shortcutConflicts) ?? false
    }

    /// Why the hotkey won't work, if it won't — shown in Settings instead of failing silently.
    var hotkeyProblem: String? {
        guard prefs.hotkey != nil else { return nil }
        if !hotkeyAvailable { return "Another app already uses this shortcut. Choose a different one." }
        if hotkeyConflictsWithZoom { return "Zoom uses this shortcut too, so it gets the key first. Change it in Zoom → Settings → Keyboard Shortcuts." }
        return nil
    }

    /// The menu's Mute / Unmute item.
    func toggleMute() {
        guard monitor.state.isInMeeting else { return }
        setZoom(muted: monitor.state == .live)
    }

    func registerHotkey() {
        press.cancel()  // a press of the old combo will never see its release
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
        let state = monitor.state
        log.info("key down in state \(String(describing: state), privacy: .public)")
        guard press.press(at: ProcessInfo.processInfo.systemUptime, inMeeting: state.isInMeeting) else { return }
        stateAtPress = state
        setZoom(muted: state == .live)
    }

    private func keyUp() {
        if press.release(at: ProcessInfo.processInfo.systemUptime) { setZoom(muted: stateAtPress == .muted) }
    }

    private func setZoom(muted: Bool) {
        // Demo mode has no Zoom to press; flash anyway so the flash can be previewed.
        if DemoMode.isOn {
            if prefs.showFlash { flash.show(live: !muted) }
            return
        }
        let pressed = zoom.set(muted: muted)
        log.info("asked Zoom for muted=\(muted, privacy: .public), press succeeded=\(pressed, privacy: .public)")
        // Zoom's menu takes up to ~1.3 s to reflect the press; show the requested state now and let polling
        // confirm it (or put Zoom's real state back if it never does — see OptimisticState).
        guard pressed else { return }
        monitor.expect(muted ? .muted : .live)
        if prefs.showFlash { flash.show(live: !muted) }
    }

    func requestAccessibility() {
        // Shows the system prompt and adds OnAir to the Accessibility list in System Settings.
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }
}
