import Foundation
import Observation
import OnAirCore
import os

/// The single source of truth for the mic state. Every display reads `state`.
@MainActor @Observable
final class StatusMonitor {
    private(set) var state: MicState
    @ObservationIgnored var onChange: ((MicState) -> Void)?
    @ObservationIgnored private let read: () -> MicState?
    @ObservationIgnored private var sticky = StickyState(.notRunning)
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private let log = Logger(subsystem: "com.johnciprian.OnAir", category: "state")

    init(read: @escaping () -> MicState?) {
        self.read = read
        state = .notRunning
        state = sticky.update(with: read())
        // Zoom doesn't announce mute changes, so poll. While Zoom is closed a tick is only a running-apps lookup.
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)  // .common keeps it ticking while our menu is open
        self.timer = timer
    }

    func refresh() {
        let new = sticky.update(with: read())
        guard new != state else { return }
        log.info("state \(String(describing: self.state), privacy: .public) → \(String(describing: new), privacy: .public)")
        state = new
        onChange?(new)
    }

    /// Zoom updates its menu a beat after the press, so re-read every 50 ms until the state moves.
    func refreshAfterToggle(from old: MicState, attemptsLeft: Int = 6, completion: @escaping (MicState) -> Void) {
        refresh()
        if state != old { completion(state); return }
        guard attemptsLeft > 1 else {
            log.info("no state change seen after toggle; Zoom still reports \(String(describing: self.state), privacy: .public)")
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.refreshAfterToggle(from: old, attemptsLeft: attemptsLeft - 1, completion: completion)
        }
    }
}
