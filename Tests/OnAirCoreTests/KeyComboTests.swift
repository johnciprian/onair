import AppKit
import Carbon.HIToolbox
import XCTest
@testable import OnAirCore

final class KeyComboTests: XCTestCase {
    func testLetterWithModifiers() {
        let combo = KeyCombo(keyCode: UInt16(kVK_ANSI_M), modifierFlags: [.control, .option], characters: "m")
        XCTAssertEqual(combo?.keyLabel, "M")
        XCTAssertEqual(combo?.displayString, "⌃⌥M")
        XCTAssertEqual(combo?.keycaps, ["⌃", "⌥", "M"])
    }

    func testModifierOrderIsControlOptionShiftCommand() {
        let combo = KeyCombo(keyCode: UInt16(kVK_ANSI_K), modifierFlags: [.command, .shift, .option, .control], characters: "k")
        XCTAssertEqual(combo?.displayString, "⌃⌥⇧⌘K")
    }

    func testCarbonModifiers() {
        let combo = KeyCombo(keyCode: UInt16(kVK_ANSI_M), modifierFlags: [.control, .command], characters: "m")
        XCTAssertEqual(combo?.carbonModifiers, UInt32(controlKey | cmdKey))
    }

    func testRejectsBareKey() {
        XCTAssertNil(KeyCombo(keyCode: UInt16(kVK_ANSI_M), modifierFlags: [], characters: "m"))
    }

    func testRejectsShiftOnly() {
        XCTAssertNil(KeyCombo(keyCode: UInt16(kVK_ANSI_M), modifierFlags: [.shift], characters: "M"))
    }

    /// ⌥+letter types characters (µ, é) and is a dead key on some layouts.
    func testRejectsOptionOnly() {
        XCTAssertNil(KeyCombo(keyCode: UInt16(kVK_ANSI_M), modifierFlags: [.option], characters: "µ"))
        XCTAssertNil(KeyCombo(keyCode: UInt16(kVK_ANSI_E), modifierFlags: [.option, .shift], characters: "´"))
    }

    func testAllowsCommandOrControl() {
        XCTAssertNotNil(KeyCombo(keyCode: UInt16(kVK_ANSI_M), modifierFlags: [.command, .shift], characters: "m"))
        XCTAssertNotNil(KeyCombo(keyCode: UInt16(kVK_ANSI_M), modifierFlags: [.control], characters: "m"))
    }

    func testAllowsF13ThroughF20Alone() {
        XCTAssertEqual(KeyCombo(keyCode: UInt16(kVK_F13), modifierFlags: [.function], characters: nil)?.displayString, "F13")
        XCTAssertEqual(KeyCombo(keyCode: UInt16(kVK_F20), modifierFlags: [], characters: nil)?.keyLabel, "F20")
    }

    func testRejectsF1AloneButAllowsItWithModifier() {
        XCTAssertNil(KeyCombo(keyCode: UInt16(kVK_F1), modifierFlags: [], characters: nil))
        XCTAssertEqual(KeyCombo(keyCode: UInt16(kVK_F1), modifierFlags: [.control], characters: nil)?.displayString, "⌃F1")
    }

    func testIgnoresNonModifierFlags() {
        let combo = KeyCombo(keyCode: UInt16(kVK_ANSI_M), modifierFlags: [.control, .function, .capsLock, .numericPad], characters: "m")
        XCTAssertEqual(combo?.modifierFlags, [.control])
        XCTAssertEqual(combo?.displayString, "⌃M")
    }

    func testSpecialKeyLabels() {
        XCTAssertEqual(KeyCombo.label(forKeyCode: UInt16(kVK_Space), characters: " "), "Space")
        XCTAssertEqual(KeyCombo.label(forKeyCode: UInt16(kVK_LeftArrow), characters: nil), "←")
        XCTAssertEqual(KeyCombo.label(forKeyCode: UInt16(kVK_Return), characters: "\r"), "↩")
        XCTAssertEqual(KeyCombo.label(forKeyCode: 200, characters: nil), "Key 200")
    }

    func testCodableRoundTrip() throws {
        let combo = try XCTUnwrap(KeyCombo(keyCode: UInt16(kVK_ANSI_M), modifierFlags: [.control, .option], characters: "m"))
        let decoded = try JSONDecoder().decode(KeyCombo.self, from: JSONEncoder().encode(combo))
        XCTAssertEqual(decoded, combo)
    }
}
