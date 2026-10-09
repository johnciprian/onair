import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var monitor: StatusMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let zoom = ZoomController()
        monitor = StatusMonitor(read: DemoMode.isOn ? DemoMode.read : zoom.readState)
    }
}
