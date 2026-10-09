import XCTest
@testable import OnAirCore

final class PressLogicTests: XCTestCase {
    func testTapTogglesOnPressOnly() {
        var logic = PressLogic()
        XCTAssertTrue(logic.press(at: 10, inMeeting: true))
        XCTAssertFalse(logic.release(at: 10.1))
    }

    func testHoldTogglesBackOnRelease() {
        var logic = PressLogic()
        XCTAssertTrue(logic.press(at: 10, inMeeting: true))
        XCTAssertTrue(logic.release(at: 10.5))
    }

    func testThresholdIsInclusive() {
        var logic = PressLogic()
        _ = logic.press(at: 10, inMeeting: true)
        XCTAssertTrue(logic.release(at: 10.3))
    }

    func testJustUnderThresholdIsATap() {
        var logic = PressLogic()
        _ = logic.press(at: 10, inMeeting: true)
        XCTAssertFalse(logic.release(at: 10.299))
    }

    func testKeyRepeatWhileHeldIsIgnored() {
        var logic = PressLogic()
        XCTAssertTrue(logic.press(at: 10, inMeeting: true))
        XCTAssertFalse(logic.press(at: 10.05, inMeeting: true))
        XCTAssertFalse(logic.press(at: 10.1, inMeeting: true))
        XCTAssertTrue(logic.release(at: 10.6))
    }

    func testPressOutsideMeetingDoesNothingEvenIfHeld() {
        var logic = PressLogic()
        XCTAssertFalse(logic.press(at: 10, inMeeting: false))
        XCTAssertFalse(logic.release(at: 11))
    }

    func testReleaseWithoutPressDoesNothing() {
        var logic = PressLogic()
        XCTAssertFalse(logic.release(at: 5))
    }

    /// If the Mac sleeps mid-hold the key-up never arrives; cancelling must let the next press work.
    func testCancelClearsAStuckPress() {
        var logic = PressLogic()
        _ = logic.press(at: 10, inMeeting: true)
        logic.cancel()
        XCTAssertTrue(logic.press(at: 500, inMeeting: true))
    }

    func testStateResetsBetweenPresses() {
        var logic = PressLogic()
        _ = logic.press(at: 10, inMeeting: true)
        _ = logic.release(at: 11)
        XCTAssertTrue(logic.press(at: 20, inMeeting: true))
        XCTAssertFalse(logic.release(at: 20.1))
    }
}
