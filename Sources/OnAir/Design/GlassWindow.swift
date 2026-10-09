import AppKit
import SwiftUI

/// Borderless windows can't take keyboard focus by default; the recorder and onboarding need it.
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// An AppKit view behind SwiftUI content that drags its window. SwiftUI swallows the mouse-downs that
/// `isMovableByWindowBackground` relies on; clicks on empty glass or text fall through to this view, while
/// buttons on top still get theirs.
struct WindowDragArea: NSViewRepresentable {
    final class DragView: NSView {
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
        override func mouseDown(with event: NSEvent) { window?.performDrag(with: event) }
    }

    func makeNSView(context: Context) -> DragView { DragView() }
    func updateNSView(_ nsView: DragView, context: Context) {}
}

/// A chromeless window whose SwiftUI content draws its own glass shape — used for the recorder and onboarding.
/// Content puts `WindowDragArea()` in its background to be draggable.
@MainActor
enum GlassWindow {
    static func make<Content: View>(content: Content) -> NSPanel {
        let host = NSHostingView(rootView: content)
        let panel = KeyablePanel(contentRect: NSRect(origin: .zero, size: host.fittingSize), styleMask: [.borderless], backing: .buffered, defer: false)
        panel.contentView = host
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        // Floating so it can't open buried behind other apps (macOS may not activate a just-launched menu bar app).
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        // Panels hide when their app isn't active, and macOS may refuse to activate a just-launched menu bar app.
        panel.hidesOnDeactivate = false
        return panel
    }
}
