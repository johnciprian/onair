import AppKit
import SwiftUI

/// Borderless windows can't take keyboard focus by default; the recorder and onboarding need it.
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// A chromeless window whose SwiftUI content draws its own glass shape — used for the recorder and onboarding.
@MainActor
enum GlassWindow {
    static func make<Content: View>(content: Content) -> NSPanel {
        let host = NSHostingView(rootView: content)
        let panel = KeyablePanel(contentRect: NSRect(origin: .zero, size: host.fittingSize), styleMask: [.borderless], backing: .buffered, defer: false)
        panel.contentView = host
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        return panel
    }
}
