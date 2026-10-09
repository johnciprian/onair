import OnAirCore
import SwiftUI

/// What sits in the menu bar. Live is a lit red capsule; muted is a quiet outline; otherwise a plain mic glyph.
struct MenuBarPill: View {
    let monitor: StatusMonitor
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        content.animation(.snappy, value: monitor.state)
    }

    @ViewBuilder private var content: some View {
        switch monitor.state {
        case .live:
            SignLabel(live: true, size: 9.5)
                .padding(.horizontal, 8)
                .frame(height: 18)
                .background(Capsule().fill(Theme.signalGradient))
                // A faint top highlight makes the fill read as lit glass rather than flat paint.
                .overlay(Capsule().strokeBorder(LinearGradient(colors: [.white.opacity(0.25), .clear], startPoint: .top, endPoint: .center), lineWidth: 1))
                .overlay(Capsule().strokeBorder(.white.opacity(contrast == .increased ? 0.9 : 0), lineWidth: 1))
        case .muted:
            SignLabel(live: false, size: 9.5)
                .padding(.horizontal, 8)
                .frame(height: 18)
                .overlay(Capsule().strokeBorder(.primary.opacity(contrast == .increased ? 1 : 0.45), lineWidth: 1))
        case .noMeeting, .notRunning:
            Image(systemName: "mic")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        case .noPermission:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.yellow)
        }
    }
}
