import XCTest
@testable import OnAirCore

final class OptimisticStateTests: XCTestCase {
    func testWithoutAnExpectationTheReadingIsShown() {
        var state = OptimisticState()
        XCTAssertEqual(state.resolve(reading: .muted, at: 10), .muted)
    }

    /// Zoom's menu still says "muted" for up to ~1.3 s after a successful unmute press; keep showing "live".
    func testStaleReadingIsHiddenWhileWaitingForZoom() {
        var state = OptimisticState()
        state.expect(.live, from: .muted, at: 10)
        XCTAssertEqual(state.resolve(reading: .muted, at: 10.5), .live)
        XCTAssertEqual(state.resolve(reading: .muted, at: 11.9), .live)
    }

    func testConfirmationClearsTheExpectation() {
        var state = OptimisticState()
        state.expect(.live, from: .muted, at: 10)
        XCTAssertEqual(state.resolve(reading: .live, at: 10.4), .live)
        // Confirmed, so a later genuine change (muted from Zoom's own button) shows right away.
        XCTAssertEqual(state.resolve(reading: .muted, at: 11), .muted)
    }

    /// If Zoom never confirms (the press silently failed), the display goes back to the truth.
    func testZoomsStateWinsAfterTheTimeout() {
        var state = OptimisticState()
        state.expect(.live, from: .muted, at: 10)
        XCTAssertEqual(state.resolve(reading: .muted, at: 10 + OptimisticState.timeout), .muted)
    }

    /// A reading that is neither the old nor the requested state (e.g. the meeting ended) is real news.
    func testUnrelatedReadingWinsImmediately() {
        var state = OptimisticState()
        state.expect(.live, from: .muted, at: 10)
        XCTAssertEqual(state.resolve(reading: .noMeeting, at: 10.2), .noMeeting)
        XCTAssertEqual(state.resolve(reading: .muted, at: 10.4), .muted)
    }
}
