import XCTest
@testable import OnAirCore

final class ZoomMenuTests: XCTestCase {
    func testMuteAudioItemMeansLive() {
        XCTAssertEqual(ZoomMenu.state(fromMeetingMenuTitles: ["Invite", "Mute audio", "Stop video"]), .live)
    }

    func testUnmuteAudioItemMeansMuted() {
        XCTAssertEqual(ZoomMenu.state(fromMeetingMenuTitles: ["Invite", "Unmute audio", "Stop video"]), .muted)
    }

    func testTelephoneVariants() {
        XCTAssertEqual(ZoomMenu.state(fromMeetingMenuTitles: ["Mute telephone"]), .live)
        XCTAssertEqual(ZoomMenu.state(fromMeetingMenuTitles: ["Unmute telephone"]), .muted)
    }

    func testNoMuteItemMeansNoMeeting() {
        XCTAssertEqual(ZoomMenu.state(fromMeetingMenuTitles: ["Invite", "Stop video"]), .noMeeting)
        XCTAssertEqual(ZoomMenu.state(fromMeetingMenuTitles: []), .noMeeting)
    }

    func testToggleTitlePicksTheVisibleItem() {
        XCTAssertEqual(ZoomMenu.toggleTitle(in: ["Invite", "Unmute audio"]), "Unmute audio")
        XCTAssertEqual(ZoomMenu.toggleTitle(in: ["Mute telephone", "Invite"]), "Mute telephone")
        XCTAssertNil(ZoomMenu.toggleTitle(in: ["Invite"]))
    }

    func testIsInMeeting() {
        XCTAssertTrue(MicState.live.isInMeeting)
        XCTAssertTrue(MicState.muted.isInMeeting)
        XCTAssertFalse(MicState.noMeeting.isInMeeting)
        XCTAssertFalse(MicState.notRunning.isInMeeting)
        XCTAssertFalse(MicState.noPermission.isInMeeting)
    }
}
