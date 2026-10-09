import SwiftUI

extension View {
    /// Liquid Glass that lights up red when live. Tinted glass alone reads as grey with a pink haze, so the live
    /// state fills the shape with signal red (under a faint top highlight) and lets the glass form the rim.
    func litGlass<S: Shape>(_ live: Bool, in shape: S) -> some View {
        background(shape.fill(Theme.signalGradient).opacity(live ? 0.92 : 0))
            .overlay(shape.stroke(LinearGradient(colors: [.white.opacity(live ? 0.35 : 0), .clear], startPoint: .top, endPoint: .center), lineWidth: 1))
            .glassEffect(.regular, in: shape)
    }
}
