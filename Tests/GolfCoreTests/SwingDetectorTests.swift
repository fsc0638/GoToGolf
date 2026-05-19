import XCTest
@testable import GolfCore

final class SwingDetectorTests: XCTestCase {

    func testRealSwingDetectedAndConfirmed() {
        let d = SwingDetector()
        XCTAssertNil(d.feed(MotionSample(g: 1.0, timestamp: 0)))
        XCTAssertNil(d.feed(MotionSample(g: 5.0, timestamp: 0.1)))   // peak
        let tentative = d.feed(MotionSample(g: 0.3, timestamp: 0.4)) // trough
        XCTAssertNotNil(tentative)
        XCTAssertTrue(d.isAwaitingDisplacementConfirmation)

        let confirmed = d.confirm(displacementMeters: 30, at: 3.0)
        XCTAssertNotNil(confirmed)
        XCTAssertGreaterThan(confirmed!.confidence, tentative!.confidence)
        XCTAssertLessThanOrEqual(confirmed!.confidence, 1.0)
        XCTAssertFalse(d.isAwaitingDisplacementConfirmation)
    }

    func testPracticeSwingRejectedWithoutDisplacement() {
        let d = SwingDetector()
        _ = d.feed(MotionSample(g: 5.0, timestamp: 0))
        XCTAssertNotNil(d.feed(MotionSample(g: 0.3, timestamp: 0.3)))
        // Ball never moved -> not a stroke.
        XCTAssertNil(d.confirm(displacementMeters: 1.0, at: 1.0))
        // Eventually times out and resets.
        XCTAssertNil(d.confirm(displacementMeters: 30, at: 100))
        XCTAssertFalse(d.isAwaitingDisplacementConfirmation)
    }

    func testIdleHandMovementNeverTriggers() {
        let d = SwingDetector()
        for i in 0..<30 {
            XCTAssertNil(d.feed(MotionSample(g: 2.0, timestamp: Double(i) * 0.1)))
        }
        XCTAssertFalse(d.isAwaitingDisplacementConfirmation)
    }

    func testPeakWithoutTroughInWindowResets() {
        let d = SwingDetector()
        _ = d.feed(MotionSample(g: 5.0, timestamp: 0))         // peak
        XCTAssertNil(d.feed(MotionSample(g: 0.3, timestamp: 1.5))) // too late
        // A subsequent clean swing still works after the reset.
        _ = d.feed(MotionSample(g: 5.0, timestamp: 2.0))
        XCTAssertNotNil(d.feed(MotionSample(g: 0.3, timestamp: 2.2)))
    }
}
