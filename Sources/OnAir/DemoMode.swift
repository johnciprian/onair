import Foundation
import OnAirCore

/// `ONAIR_DEMO=1` cycles noMeeting → muted → live every 3 s, so every display can be checked without a Zoom call.
enum DemoMode {
    static let isOn = ProcessInfo.processInfo.environment["ONAIR_DEMO"] == "1"

    static func read() -> MicState {
        let states: [MicState] = [.noMeeting, .muted, .live]
        return states[Int(ProcessInfo.processInfo.systemUptime / 3) % states.count]
    }
}
