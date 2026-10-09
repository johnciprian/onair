import AppKit
import Carbon.HIToolbox
import XCTest
@testable import OnAirCore

final class ZoomShortcutTests: XCTestCase {
    private let hyperF10 = KeyCombo(keyCode: UInt16(kVK_F10), modifierFlags: [.control, .option, .shift, .command], characters: nil)!

    /// The real value Zoom stored on this Mac: F10 (109) with ⌃⌥⇧⌘ plus the fn flag (10354688).
    func testDetectsZoomUsingTheSameCombo() {
        XCTAssertTrue(ZoomShortcut.conflicts(zoomKeyCode: 109, zoomModifiers: 10_354_688, with: hyperF10))
    }

    func testDifferentKeyIsNoConflict() {
        XCTAssertFalse(ZoomShortcut.conflicts(zoomKeyCode: kVK_F9, zoomModifiers: 10_354_688, with: hyperF10))
    }

    func testSameKeyDifferentModifiersIsNoConflict() {
        let cmdShift = Int(NSEvent.ModifierFlags([.command, .shift]).rawValue)
        XCTAssertFalse(ZoomShortcut.conflicts(zoomKeyCode: 109, zoomModifiers: cmdShift, with: hyperF10))
    }

    /// What Zoom stored on this Mac after the user cleared its shortcut — this crashed the menu panel.
    func testClearedZoomShortcutIsNoConflict() {
        XCTAssertFalse(ZoomShortcut.conflicts(zoomKeyCode: -1, zoomModifiers: 0, with: hyperF10))
    }

    /// Zoom's settings file is outside our control; no value in it may crash OnAir.
    func testOutOfRangeValuesAreNoConflict() {
        XCTAssertFalse(ZoomShortcut.conflicts(zoomKeyCode: 70_000, zoomModifiers: 10_354_688, with: hyperF10))
        XCTAssertFalse(ZoomShortcut.conflicts(zoomKeyCode: 109, zoomModifiers: -5, with: hyperF10))
    }

    /// Zoom only stores the shortcut once it's been changed; until then it's the default ⌘⇧A.
    func testUnsetZoomShortcutMeansDefaultCommandShiftA() {
        let cmdShiftA = KeyCombo(keyCode: UInt16(kVK_ANSI_A), modifierFlags: [.command, .shift], characters: "a")!
        XCTAssertTrue(ZoomShortcut.conflicts(zoomKeyCode: nil, zoomModifiers: nil, with: cmdShiftA))
        XCTAssertFalse(ZoomShortcut.conflicts(zoomKeyCode: nil, zoomModifiers: nil, with: hyperF10))
    }
}
