import Foundation
import Observation
import OnAirCore
import os

/// The single source of truth for the mic state. Every display reads `state`.
@MainActor @Observable
final class StatusMonitor {
    private(set) var state: MicState
    /// Called with the old and new state.
    @ObservationIgnored var onChange: ((MicState, MicState) -> Void)?
    @ObservationIgnored private let read: () -> MicState?
    @ObservationIgnored private var sticky = StickyState(.notRunning)
    @ObservationIgnored private var optimistic = OptimisticState()
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
        let reading = sticky.update(with: read())
        show(optimistic.resolve(reading: reading, at: ProcessInfo.processInfo.systemUptime))
    }

    /// Shows `target` right away after a successful press; Zoom's lagging menu confirms it on later polls.
    func expect(_ target: MicState) {
        optimistic.expect(target, from: state, at: ProcessInfo.processInfo.systemUptime)
        show(target)
    }

    private func show(_ new: MicState) {
        guard new != state else { return }
        log.info("state \(String(describing: self.state), privacy: .public) → \(String(describing: new), privacy: .public)")
        let old = state
        state = new
        onChange?(old, new)
    }
}
