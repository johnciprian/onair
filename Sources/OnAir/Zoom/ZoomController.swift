import AppKit
import ApplicationServices
import OnAirCore

/// The only code that knows about Zoom. Reads and presses items in Zoom's "Meeting" menu through the
/// Accessibility API — the same signal the old SwiftBar script used, but in-process instead of via osascript.
final class ZoomController {
    static let bundleID = "us.zoom.xos"

    func readState() -> MicState {
        guard AXIsProcessTrusted() else { return .noPermission }
        guard let app = zoomApp() else { return .notRunning }
        return ZoomMenu.state(fromMeetingMenuTitles: meetingMenuItems(of: app).map(\.title))
    }

    /// Presses whichever Mute/Unmute item Zoom is showing. Returns false outside a meeting.
    func toggle() -> Bool {
        guard let app = zoomApp() else { return false }
        let items = meetingMenuItems(of: app)
        guard let title = ZoomMenu.toggleTitle(in: items.map(\.title)),
              let item = items.first(where: { $0.title == title })
        else { return false }
        return AXUIElementPerformAction(item.element, kAXPressAction as CFString) == .success
    }

    private func zoomApp() -> AXUIElement? {
        guard let pid = NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleID).first?.processIdentifier
        else { return nil }
        let app = AXUIElementCreateApplication(pid)
        // A hung Zoom would otherwise block our main thread for the 6 s default on every poll.
        AXUIElementSetMessagingTimeout(app, 0.25)
        return app
    }

    private func meetingMenuItems(of app: AXUIElement) -> [(title: String, element: AXUIElement)] {
        guard let menuBar: AXUIElement = attribute(app, kAXMenuBarAttribute),
              let barItems: [AXUIElement] = attribute(menuBar, kAXChildrenAttribute),
              let meeting = barItems.first(where: { (attribute($0, kAXTitleAttribute) as String?) == "Meeting" }),
              let menu = (attribute(meeting, kAXChildrenAttribute) as [AXUIElement]?)?.first,
              let items: [AXUIElement] = attribute(menu, kAXChildrenAttribute)
        else { return [] }
        return items.compactMap { item in (attribute(item, kAXTitleAttribute) as String?).map { ($0, item) } }
    }

    private func attribute<T>(_ element: AXUIElement, _ name: String) -> T? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value as? T
    }
}
