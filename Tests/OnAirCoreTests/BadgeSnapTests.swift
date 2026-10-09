import CoreGraphics
import XCTest
@testable import OnAirCore

final class BadgeSnapTests: XCTestCase {
    let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
    let size = CGSize(width: 100, height: 40)

    private func snapped(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        BadgeSnap.origin(for: CGRect(origin: CGPoint(x: x, y: y), size: size), in: screen, margin: 10)
    }

    func testDropInMiddleStaysPut() {
        XCTAssertEqual(snapped(400, 300), CGPoint(x: 400, y: 300))
    }

    func testDropNearLeftEdgeSnapsToMargin() {
        XCTAssertEqual(snapped(40, 300), CGPoint(x: 10, y: 300))
    }

    func testDropNearTopRightSnapsToCorner() {
        // Right margin line: 1000 - 10 - 100 = 890. Top margin line: 800 - 10 - 40 = 750.
        XCTAssertEqual(snapped(880, 720), CGPoint(x: 890, y: 750))
    }

    func testHalfOffscreenIsPulledBackIn() {
        XCTAssertEqual(snapped(-50, -20), CGPoint(x: 10, y: 10))
    }

    func testFrameOnDisconnectedScreenIsBroughtBack() {
        XCTAssertEqual(snapped(3000, 2000), CGPoint(x: 890, y: 750))
    }

    func testScreenWithNegativeOrigin() {
        let left = CGRect(x: -1440, y: 0, width: 1440, height: 900)
        let origin = BadgeSnap.origin(for: CGRect(x: -1400, y: 500, width: 100, height: 40), in: left, margin: 10)
        XCTAssertEqual(origin, CGPoint(x: -1430, y: 500))
    }
}
