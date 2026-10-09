import AppKit
import OnAirCore
import SwiftUI

struct BadgeView: View {
    /// Room around the capsule so the glass shadow and red bloom aren't clipped by the window edge.
    static let padding: CGFloat = 12

    let monitor: StatusMonitor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let live = monitor.state == .live
        let visible = monitor.state.isInMeeting
        SignLabel(live: live, size: 15)
            .frame(width: 160, height: 44)
            .litGlass(live, in: Capsule())
            .overlay(Capsule().strokeBorder(.primary.opacity(contrast == .increased ? 0.8 : 0), lineWidth: 1))
            .scaleEffect(visible || reduceMotion ? 1 : 0.9)
            .opacity(visible ? 1 : 0)
            .animation(.snappy, value: monitor.state)
            .padding(Self.padding)
    }
}

/// SwiftUI swallows mouse-downs, so `isMovableByWindowBackground` never sees them; start the drag explicitly.
final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

/// The draggable ON AIR badge. The window stays ordered in while enabled so the badge can animate in and out;
/// it lets clicks through whenever the badge is hidden.
@MainActor
final class BadgeWindow {
    private static let edgeMargin = 16 - BadgeView.padding

    private let panel = OverlayPanel.make(level: .statusBar)
    private let monitor: StatusMonitor
    private let prefs: Preferences
    private var snapWork: DispatchWorkItem?

    init(monitor: StatusMonitor, prefs: Preferences) {
        self.monitor = monitor
        self.prefs = prefs
        let host = DraggableHostingView(rootView: BadgeView(monitor: monitor))
        panel.contentView = host
        panel.setContentSize(host.fittingSize)
        placeAtSavedOrigin()
        NotificationCenter.default.addObserver(forName: NSWindow.didMoveNotification, object: panel, queue: .main) { [weak self] _ in
            // Only user drags (mouse held) snap and save; our own placement and snap animation must not.
            guard NSEvent.pressedMouseButtons != 0 else { return }
            MainActor.assumeIsolated { self?.scheduleSnap() }
        }
        // A display was unplugged or rearranged: bring the badge back onto a connected screen.
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            // Re-place from the saved spot without saving: a laptop that wakes before its external display
            // reconnects would otherwise lose the user's position for good.
            MainActor.assumeIsolated { self?.placeAtSavedOrigin() }
        }
    }

    func update(enabled: Bool) {
        if enabled { panel.orderFrontRegardless() } else { panel.orderOut(nil) }
        panel.ignoresMouseEvents = !(enabled && monitor.state.isInMeeting)
    }

    /// Move notifications arrive throughout a drag; snap only once the mouse button is up.
    private func scheduleSnap() {
        snapWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if NSEvent.pressedMouseButtons != 0 { scheduleSnap() } else { snap() }
        }
        snapWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }

    private func snap() {
        let frame = panel.frame
        // The screen list can be briefly empty while displays reconfigure.
        guard let screen = NSScreen.screens.first(where: { $0.frame.intersects(frame) }) ?? NSScreen.main else { return }
        let origin = BadgeSnap.origin(for: frame, in: screen.visibleFrame, margin: Self.edgeMargin)
        prefs.badgeOrigin = origin
        guard origin != frame.origin else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrameOrigin(origin)
        }
    }

    /// The saved spot if it's still on a connected screen; otherwise top-right of the main screen, under the menu bar.
    private func placeAtSavedOrigin() {
        let size = panel.frame.size
        if let saved = prefs.badgeOrigin,
           let screen = NSScreen.screens.first(where: { $0.frame.intersects(CGRect(origin: saved, size: size)) }) {
            panel.setFrameOrigin(BadgeSnap.origin(for: CGRect(origin: saved, size: size), in: screen.visibleFrame, margin: Self.edgeMargin))
        } else if let visible = NSScreen.main?.visibleFrame {
            panel.setFrameOrigin(CGPoint(x: visible.maxX - size.width - Self.edgeMargin, y: visible.maxY - size.height - Self.edgeMargin))
        }
    }
}
