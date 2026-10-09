import SwiftUI

/// The studio tally light. Lit: white with a red bloom, breathing slowly. Unlit: an empty red ring.
struct TallyDot: View {
    let lit: Bool
    let diameter: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    var body: some View {
        Circle()
            .fill(lit ? Color.white : Color.clear)
            .overlay(Circle().strokeBorder(Theme.signalRed.opacity(lit ? 0 : 0.6), lineWidth: max(1, diameter * 0.15)))
            .frame(width: diameter, height: diameter)
            .shadow(color: lit ? Theme.signalRed : .clear, radius: diameter * 0.8)
            .opacity(breathing ? 0.75 : 1)
            .animation(breathing ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .easeOut(duration: 0.2), value: breathing)
            .onChange(of: lit, initial: true) { _, isLit in breathing = isLit && !reduceMotion }
    }
}

/// "● ON AIR" / "○ OFF AIR" in the sign typeface. Every display builds on this.
struct SignLabel: View {
    let live: Bool
    let size: CGFloat

    var body: some View {
        HStack(spacing: size * 0.45) {
            TallyDot(lit: live, diameter: size * 0.6)
            Text(live ? "ON AIR" : "OFF AIR")
                .font(Theme.signFont(size: size))
                .tracking(Theme.signTracking(size: size))
                .foregroundStyle(live ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                .shadow(color: live ? Theme.signalRed.opacity(0.6) : .clear, radius: size * 0.6)
                .contentTransition(.interpolate)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(live ? "On air: your microphone is live" : "Off air: your microphone is muted")
    }
}
