import SwiftUI

/// Shared visual tokens, so the menu bar, badge, glow and flash read as one object: a lit broadcast sign.
enum Theme {
    /// A warm signal red, a touch richer than systemRed, so it reads as lit glass rather than an error.
    static let signalRed = Color(red: 1.0, green: 0.231, blue: 0.188)        // #FF3B30
    static let signalRedDeep = Color(red: 0.878, green: 0.145, blue: 0.106)  // #E0251B
    static let signalGradient = LinearGradient(colors: [signalRed, signalRedDeep], startPoint: .top, endPoint: .bottom)

    /// The "sign" voice — used only for ON AIR / OFF AIR so it stays special.
    static func signFont(size: CGFloat) -> Font { .system(size: size, weight: .black).width(.expanded) }

    static func signTracking(size: CGFloat) -> CGFloat { size * 0.12 }
}
