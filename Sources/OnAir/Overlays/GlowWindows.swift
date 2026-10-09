import AppKit
import OnAirCore
import SwiftUI

/// A thin red rim hugging the display edges that slowly breathes while live, modelled on the glow
/// macOS-style agents show while controlling the screen: contained, but impossible to miss.
struct GlowView: View {
    let monitor: StatusMonitor
    let cornerRadius: CGFloat
    @State private var dimmed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let live = monitor.state == .live
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            // A short soft falloff (~25 pt) under a bright, barely blurred rim right at the edge.
            shape.strokeBorder(Theme.signalRed.opacity(0.45), lineWidth: 10).blur(radius: 8)
            shape.strokeBorder(Theme.signalRed.opacity(0.9), lineWidth: 3).blur(radius: 1.5)
        }
        .clipShape(shape)
        .opacity(dimmed ? 0.45 : 1)
        .opacity(live ? 1 : 0)
        .animation(live ? .easeOut(duration: 0.25) : .easeIn(duration: 0.4), value: live)
        .onChange(of: live, initial: true) { _, live in
            // The breathing runs only while live (and not with Reduce Motion); a plain animation back to
            // full strength replaces the repeating one, which stops it.
            if live && !reduceMotion {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { dimmed = true }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { dimmed = false }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
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
            panel.contentView = NSHostingView(rootView: GlowView(monitor: monitor, cornerRadius: radius))
            panel.setFrame(screen.frame, display: true)
            panel.orderFrontRegardless()
            panels.append(panel)
        }
    }
}
