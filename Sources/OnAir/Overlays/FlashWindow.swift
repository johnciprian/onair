import AppKit
import Observation
import SwiftUI

@MainActor @Observable
final class FlashModel {
    enum Phase { case hidden, shown, leaving }
    var live = false
    var phase = Phase.hidden
    var bounce = 0
}

struct FlashView: View {
    let model: FlashModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: model.live ? "mic.fill" : "mic.slash.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(model.live ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: model.bounce)
            SignLabel(live: model.live, size: 14)
        }
        .frame(width: 200, height: 200)
        .litGlass(model.live, in: RoundedRectangle(cornerRadius: 46, style: .continuous))
        .scaleEffect(reduceMotion ? 1 : scale)
        .opacity(model.phase == .shown ? 1 : 0)
        .padding(30)  // room for the glass shadow
    }

    private var scale: CGFloat {
        switch model.phase {
        case .hidden: 0.85
        case .shown: 1
        case .leaving: 0.95
        }
    }
}

/// A volume-HUD-style confirmation in the middle of the screen the pointer is on.
@MainActor
final class FlashWindow {
    private let model = FlashModel()
    private let panel = OverlayPanel.make(level: .statusBar)
    private var hideWork: DispatchWorkItem?

    init() {
        let host = NSHostingView(rootView: FlashView(model: model))
        panel.contentView = host
        panel.setContentSize(host.fittingSize)
        panel.ignoresMouseEvents = true
    }

    func show(live: Bool) {
        let mouse = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main {
            panel.setFrameOrigin(NSPoint(x: screen.frame.midX - panel.frame.width / 2, y: screen.frame.midY - panel.frame.height / 2))
        }
        panel.orderFrontRegardless()
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        // A second toggle while visible updates in place (symbol replace) instead of re-entering.
        if model.phase == .leaving { model.phase = .hidden }
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .bouncy) {
            model.live = live
            model.phase = .shown
        }
        model.bounce += 1
        schedule(after: 0.9) { [weak self] in self?.hide() }  // ~0.3 s entrance + 0.6 s hold
    }

    private func hide() {
        withAnimation(.easeOut(duration: 0.25)) { model.phase = .leaving }
        schedule(after: 0.3) { [weak self] in
            self?.model.phase = .hidden
            self?.panel.orderOut(nil)
        }
    }

    private func schedule(after delay: TimeInterval, _ action: @escaping () -> Void) {
        hideWork?.cancel()
        let work = DispatchWorkItem(block: action)
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
}
