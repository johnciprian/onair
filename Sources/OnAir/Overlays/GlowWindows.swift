import AppKit
import OnAirCore
import SwiftUI

/// A thin red rim hugging the display edges that slowly breathes while live, modelled on the glow
/// macOS-style agents show while controlling the screen: contained, but impossible to miss.
struct GlowView: View {
    let monitor: StatusMonitor
    let cornerRadius: CGFloat
    @State private var liveSince = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// One full breath, bright → dim → bright.
    private static let cycle: TimeInterval = 2.4
    private static let dimmest = 0.45

    var body: some View {
        let live = monitor.state == .live
        // The breath is read off the clock instead of a repeating animation. A repeating animation also
        // catches any layout change made in the same transaction (the window sizing to its display), which
        // made the rim sweep out from the top-left corner forever instead of breathing in place.
        TimelineView(.animation(paused: !live || reduceMotion)) { context in
            rim.opacity(reduceMotion ? 1 : breath(at: context.date))
        }
        .opacity(live ? 1 : 0)
        .animation(live ? .easeOut(duration: 0.25) : .easeIn(duration: 0.4), value: live)
        .onChange(of: live, initial: true) { _, live in
            if live { liveSince = Date() }  // each live stretch starts at full strength
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var rim: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return ZStack {
            // A soft falloff (~35 pt) under a bright, lightly blurred rim right at the edge.
            shape.strokeBorder(Theme.signalRed.opacity(0.45), lineWidth: 16).blur(radius: 14)
            shape.strokeBorder(Theme.signalRed.opacity(0.85), lineWidth: 4).blur(radius: 4)
        }
        .clipShape(shape)
    }

    /// Eases between full strength and `dimmest` along a cosine, so every edge brightens and dims together.
    private func breath(at date: Date) -> Double {
        let phase = date.timeIntervalSince(liveSince) / Self.cycle * 2 * .pi
        return Self.dimmest + (1 - Self.dimmest) * (1 + cos(phase)) / 2
    }
}

/// One click-through glow window per display, rebuilt when displays change. Windows stay up while enabled
/// so the glow can fade in and out; the view itself is transparent unless live.
@MainActor
final class GlowWindows {
    private let monitor: StatusMonitor
    private var panels: [NSPanel] = []
    private var enabled = false

    init(monitor: StatusMonitor) {
        self.monitor = monitor
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.rebuild() }
        }
    }

    func setEnabled(_ on: Bool) {
        guard on != enabled else { return }
        enabled = on
        rebuild()
    }

    private func rebuild() {
        panels.forEach { $0.orderOut(nil) }
        panels = []
        guard enabled else { return }
        for screen in NSScreen.screens {
            // macOS has no API for a display's corner radius; notched built-in displays have rounded corners.
            let radius: CGFloat = screen.safeAreaInsets.top > 0 ? 10 : 0
            let panel = OverlayPanel.make(level: .screenSaver)  // above the menu bar, so the top edge glows too
            panel.ignoresMouseEvents = true
            // Size the window before the view goes in, so the view lays out once at full size.
            panel.setFrame(screen.frame, display: false)
            panel.contentView = NSHostingView(rootView: GlowView(monitor: monitor, cornerRadius: radius))
            panel.orderFrontRegardless()
            panels.append(panel)
        }
    }
}
