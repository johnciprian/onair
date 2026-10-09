import XCTest
@testable import OnAirCore

final class StickyStateTests: XCTestCase {
    func testSuccessfulReadIsShown() {
        var sticky = StickyState(.notRunning)
        XCTAssertEqual(sticky.update(with: .live), .live)
    }

    /// A busy Zoom must not flash "not in a meeting" while the mic is live.
    func testFailedReadKeepsLastKnownState() {
        var sticky = StickyState(.notRunning)
        _ = sticky.update(with: .live)
        for _ in 0..<StickyState.maxMisses {
            XCTAssertEqual(sticky.update(with: nil), .live)
        }
    }

    func testPersistentFailureFallsBackToNoMeeting() {
        var sticky = StickyState(.notRunning)
        _ = sticky.update(with: .live)
        for _ in 0..<StickyState.maxMisses { _ = sticky.update(with: nil) }
        XCTAssertEqual(sticky.update(with: nil), .noMeeting)
    }

    func testSuccessfulReadResetsMissCount() {
        var sticky = StickyState(.notRunning)
        _ = sticky.update(with: .live)
        for _ in 0..<StickyState.maxMisses { _ = sticky.update(with: nil) }
        _ = sticky.update(with: .muted)
        for _ in 0..<StickyState.maxMisses {
            XCTAssertEqual(sticky.update(with: nil), .muted)
        }
    }
}
