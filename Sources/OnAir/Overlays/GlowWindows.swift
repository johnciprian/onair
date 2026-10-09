import AppKit
import OnAirCore
import SwiftUI

/// A crisp red line hugging the display edge with a soft falloff inward. Calm — no pulsing — but impossible to miss.
struct GlowView: View {
    let monitor: StatusMonitor
    let cornerRadius: CGFloat

    var body: some View {
        let live = monitor.state == .live
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            // Narrow stroke + blur ≈ a 40–48 pt falloff; wider washed the whole menu bar red.
            shape.strokeBorder(Theme.signalRed.opacity(0.4), lineWidth: 20).blur(radius: 20)
            shape.strokeBorder(Theme.signalRed, lineWidth: 2)
        }
        .clipShape(shape)
        .opacity(live ? 1 : 0)
        .animation(live ? .easeOut(duration: 0.25) : .easeIn(duration: 0.4), value: live)
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
