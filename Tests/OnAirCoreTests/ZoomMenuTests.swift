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

    func testPressTitleMutesWhenLive() {
        XCTAssertEqual(ZoomMenu.pressTitle(toMute: true, in: ["Invite", "Mute audio"]), "Mute audio")
        XCTAssertEqual(ZoomMenu.pressTitle(toMute: true, in: ["Mute telephone"]), "Mute telephone")
    }

    func testPressTitleUnmutesWhenMuted() {
        XCTAssertEqual(ZoomMenu.pressTitle(toMute: false, in: ["Invite", "Unmute audio"]), "Unmute audio")
    }

    /// Release after a failed push-to-talk press must not unmute: Zoom is already muted, so there's nothing to press.
    func testPressTitleIsNilWhenAlreadyInTargetState() {
        XCTAssertNil(ZoomMenu.pressTitle(toMute: true, in: ["Unmute audio"]))
        XCTAssertNil(ZoomMenu.pressTitle(toMute: false, in: ["Mute audio"]))
    }

    func testPressTitleIsNilOutsideAMeeting() {
        XCTAssertNil(ZoomMenu.pressTitle(toMute: true, in: ["Invite"]))
    }

    func testIsInMeeting() {
        XCTAssertTrue(MicState.live.isInMeeting)
        XCTAssertTrue(MicState.muted.isInMeeting)
        XCTAssertFalse(MicState.noMeeting.isInMeeting)
        XCTAssertFalse(MicState.notRunning.isInMeeting)
        XCTAssertFalse(MicState.noPermission.isInMeeting)
    }
}
