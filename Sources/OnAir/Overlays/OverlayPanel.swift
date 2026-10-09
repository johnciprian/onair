import AppKit

@MainActor
enum OverlayPanel {
    /// A transparent, non-activating panel that floats on every Space and over full-screen apps. It asks macOS
    /// to leave it out of screen sharing, so meeting participants don't see your status overlays.
    static func make(level: NSWindow.Level) -> NSPanel {
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = level
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        // Demo mode stays capturable so the overlays can be checked in screenshots.
        panel.sharingType = DemoMode.isOn ? .readOnly : .none
        panel.isReleasedWhenClosed = false
        return panel
    }
}
