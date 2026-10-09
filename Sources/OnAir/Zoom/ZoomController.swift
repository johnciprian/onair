import AppKit
import ApplicationServices
import OnAirCore

/// The only code that knows about Zoom. Reads and presses items in Zoom's "Meeting" menu through the
/// Accessibility API — the same signal the old SwiftBar script used, but in-process instead of via osascript.
final class ZoomController {
    static let bundleID = "us.zoom.xos"

    init() {
        // The default for every AX call this process makes (menu items included, not just the app element),
        // so a hung Zoom can't block our main thread for the 6 s system default.
        AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 0.25)
    }

    /// nil when Zoom didn't answer (busy or hung) — distinct from "no meeting", so the display can hold its last state.
    func readState() -> MicState? {
        guard AXIsProcessTrusted() else { return .noPermission }
        guard let app = zoomApp() else { return .notRunning }
        return meetingMenuItems(of: app).map { ZoomMenu.state(fromMeetingMenuTitles: $0.map(\.title)) }
    }

    /// Presses Mute or Unmute to reach `muted`. Returns false when Zoom is already there or not in a meeting.
    func set(muted: Bool) -> Bool {
        guard let app = zoomApp(),
              let items = meetingMenuItems(of: app),
              let title = ZoomMenu.pressTitle(toMute: muted, in: items.map(\.title)),
              let item = items.first(where: { $0.title == title })
        else { return false }
        return AXUIElementPerformAction(item.element, kAXPressAction as CFString) == .success
    }

    /// True when Zoom's own Mute/Unmute shortcut is this combo — Zoom then gets the key press instead of OnAir.
    func shortcutConflicts(with combo: KeyCombo) -> Bool {
        let stored = UserDefaults(suiteName: "us.zoom.xos.Hotkey")?.dictionary(forKey: "[HK@combo]-HotkeyOnOffAudio")
        return ZoomShortcut.conflicts(zoomKeyCode: stored?["hot key code"] as? Int,
                                      zoomModifiers: stored?["hot key modifier"] as? Int,
                                      with: combo)
    }

    private func zoomApp() -> AXUIElement? {
        guard let pid = NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleID).first?.processIdentifier
        else { return nil }
        let app = AXUIElementCreateApplication(pid)
        // A hung Zoom would otherwise block our main thread for the 6 s default on every poll.
        AXUIElementSetMessagingTimeout(app, 0.25)
        return app
    }

    /// nil when Zoom's menu bar couldn't be read; empty when there's no Meeting menu (not in a meeting).
    private func meetingMenuItems(of app: AXUIElement) -> [(title: String, element: AXUIElement)]? {
        guard let menuBar: AXUIElement = attribute(app, kAXMenuBarAttribute),
              let barItems: [AXUIElement] = attribute(menuBar, kAXChildrenAttribute)
        else { return nil }
        guard let meeting = barItems.first(where: { (attribute($0, kAXTitleAttribute) as String?) == "Meeting" })
        else { return [] }
        guard let menu = (attribute(meeting, kAXChildrenAttribute) as [AXUIElement]?)?.first,
              let items: [AXUIElement] = attribute(menu, kAXChildrenAttribute)
        else { return nil }
        return items.compactMap { item in (attribute(item, kAXTitleAttribute) as String?).map { ($0, item) } }
    }

    private func attribute<T>(_ element: AXUIElement, _ name: String) -> T? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value as? T
    }
}
