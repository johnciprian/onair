import Foundation
import OnAirCore

/// The user's choices, stored in UserDefaults. Bools default to false, which is what makes every
/// display except the menu bar start switched off.
final class Preferences {
    private let defaults = UserDefaults.standard

    var showBadge: Bool {
        get { defaults.bool(forKey: "showBadge") }
        set { defaults.set(newValue, forKey: "showBadge") }
    }

    var showGlow: Bool {
        get { defaults.bool(forKey: "showGlow") }
        set { defaults.set(newValue, forKey: "showGlow") }
    }

    var showFlash: Bool {
        get { defaults.bool(forKey: "showFlash") }
        set { defaults.set(newValue, forKey: "showFlash") }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: "hasCompletedOnboarding") }
        set { defaults.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    var hotkey: KeyCombo? {
        get { defaults.data(forKey: "hotkey").flatMap { try? JSONDecoder().decode(KeyCombo.self, from: $0) } }
        set { defaults.set(newValue.flatMap { try? JSONEncoder().encode($0) }, forKey: "hotkey") }
    }

    var badgeOrigin: CGPoint? {
        get { defaults.string(forKey: "badgeOrigin").map(NSPointFromString) }
        set { defaults.set(newValue.map(NSStringFromPoint), forKey: "badgeOrigin") }
    }
}
