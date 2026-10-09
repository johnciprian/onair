import Sparkle

/// In-app updates through Sparkle, from the appcast attached to each GitHub release (see scripts/release.sh).
/// `@preconcurrency`: Sparkle's Objective-C delegate isn't annotated, but it calls its delegate on the main thread.
@MainActor
final class Updater: NSObject, @preconcurrency SPUStandardUserDriverDelegate {
    /// A background check found an update the user hasn't looked at yet; the menu says so until they do.
    private(set) var hasUnseenUpdate = false
    private var controller: SPUStandardUpdaterController!

    override init() {
        super.init()
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: self)
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }

    // OnAir has no Dock icon, so an update window from a background check opens behind other apps and is easy
    // to miss. Sparkle calls the fix "gentle reminders": also flag the update in OnAir's own menu.
    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        if !state.userInitiated { hasUnseenUpdate = true }
    }

    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        hasUnseenUpdate = false
    }

    func standardUserDriverWillFinishUpdateSession() {
        hasUnseenUpdate = false
    }
}
