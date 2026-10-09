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

/// A chromeless Liquid Glass window — used for the recorder and onboarding. Following Apple's AppKit guidance
/// (WWDC25 "Build an AppKit app with the new design"), the content sits *inside* an NSGlassEffectView that is the
/// window's whole content, sized to it, with `cornerRadius` giving the shape. SwiftUI glass drawn inside a larger
/// window left a faint rectangular backdrop around the rounded glass.
/// Content puts `WindowDragArea()` in its background to be draggable.
@MainActor
enum GlassWindow {
    static func make<Content: View>(content: Content, cornerRadius: CGFloat) -> NSPanel {
        let host = NSHostingView(rootView: content)
        let glass = NSGlassEffectView()
        glass.cornerRadius = cornerRadius
        glass.contentView = host
        let panel = KeyablePanel(contentRect: NSRect(origin: .zero, size: host.fittingSize), styleMask: [.borderless], backing: .buffered, defer: false)
        panel.contentView = glass
        panel.isOpaque = false
        panel.backgroundColor = .clear
        // The system shadow traces the square window frame (a dark outline around the rounded glass), not the glass.
        panel.hasShadow = false
        // Floating so it can't open buried behind other apps (macOS may not activate a just-launched menu bar app).
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        // Panels hide when their app isn't active, and macOS may refuse to activate a just-launched menu bar app.
        panel.hidesOnDeactivate = false
        return panel
    }
}
