import XCTest
@testable import GolfCore

final class RoundSessionTests: XCTestCase {

    private func course() -> Course {
        func hole(_ n: Int, tee: GeoCoordinate) -> Hole {
            let green = GreenPoints(
                front:  GeoCoordinate(latitude: tee.latitude, longitude: tee.longitude + 0.0010),
                center: GeoCoordinate(latitude: tee.latitude, longitude: tee.longitude + 0.0015),
                back:   GeoCoordinate(latitude: tee.latitude, longitude: tee.longitude + 0.0020)
            )
            return Hole(id: n, par: 4, strokeIndex: n, tee: tee, green: green)
        }
        return Course(
            id: "C", name: "Range Nine",
            holes: [
                hole(1, tee: GeoCoordinate(latitude: 25.000, longitude: 121.0)),
                hole(2, tee: GeoCoordinate(latitude: 25.010, longitude: 121.0)),
                hole(3, tee: GeoCoordinate(latitude: 25.020, longitude: 121.0))
            ],
            ratings: [.white: TeeRating(courseRating: 72, slopeRating: 113)]
        )
    }

    /// Detect + GPS-confirm one real stroke.
    private func playStroke(_ s: RoundSession, at base: TimeInterval) {
        _ = s.ingest(motion: MotionSample(g: 1.0, timestamp: base))
        _ = s.ingest(motion: MotionSample(g: 5.0, timestamp: base + 0.1))   // peak
        _ = s.ingest(motion: MotionSample(g: 0.3, timestamp: base + 0.4))   // trough
        let recorded = s.confirmSwing(displacementMeters: 30, at: base + 3)  // ball moved
        XCTAssertTrue(recorded)
    }

    func testPlayARoundEndToEnd() {
        let s = RoundSession(course: course(), teeBox: .white)
        XCTAssertEqual(s.currentHole, 1)

        // Strategy data is available for the current hole.
        let d = s.greenDistances(playerAt: GeoCoordinate(latitude: 25.0, longitude: 121.0))
        XCTAssertNotNil(d)
        XCTAssertGreaterThan(d!.centerYards, 0)

        // Noise while not dwelling in hole 2's tee box must not advance.
        XCTAssertEqual(
            s.updateLocation(GeoCoordinate(latitude: 25.0, longitude: 121.0), now: 5),
            .blockedStillLocked
        )
        XCTAssertEqual(s.currentHole, 1)

        // Four real strokes on hole 1.
        for i in 0..<4 { playStroke(s, at: Double(i) * 20) }
        XCTAssertEqual(s.currentRound.scores.first { $0.holeNumber == 1 }?.gross, 4)
        XCTAssertEqual(s.pendingSyncCount, 4)

        // Walk to hole 2 tee and dwell the required 30 s.
        let teeB = GeoCoordinate(latitude: 25.010, longitude: 121.0)
        XCTAssertEqual(s.updateLocation(teeB, now: 1000), .blockedStillLocked)
        XCTAssertEqual(s.updateLocation(teeB, now: 1031), .advanced(toHole: 2))
        XCTAssertEqual(s.currentHole, 2)

        // Manual scorecard entry on hole 2.
        s.recordGross(5)
        XCTAssertEqual(s.currentRound.scores.first { $0.holeNumber == 2 }?.gross, 5)
        XCTAssertEqual(s.pendingSyncCount, 5)

        // Finish.
        let finished = s.finishRound()
        XCTAssertEqual(finished.status, .completed)
        XCTAssertNotNil(finished.finishedAt)
        XCTAssertEqual(finished.scores.first { $0.holeNumber == 3 }?.gross, 0)

        // All queued updates flush to the paired device losslessly.
        var sent: [Int] = []
        let count = s.drainSync { sent.append($0.value); return true }
        XCTAssertEqual(count, 5)
        XCTAssertEqual(sent, [1, 2, 3, 4, 5])   // 4 swing increments + gross 5
        XCTAssertEqual(s.pendingSyncCount, 0)
    }

    func testManualJumpRequiresSafeGesture() {
        let s = RoundSession(course: course(), teeBox: .white)
        XCTAssertEqual(
            s.manualJump(to: 3, gesture: SafeGesture(twoFingerLongPress: false, swipe: true)),
            .rejectedInvalidGesture
        )
        XCTAssertEqual(s.currentHole, 1)
        XCTAssertEqual(
            s.manualJump(to: 3, gesture: SafeGesture(twoFingerLongPress: true, swipe: true)),
            .advanced(toHole: 3)
        )
        XCTAssertEqual(s.currentHole, 3)
    }

    func testUndoLastEditQueuesCorrection() {
        let s = RoundSession(course: course(), teeBox: .white)
        s.recordGross(7)
        XCTAssertEqual(s.currentRound.scores.first { $0.holeNumber == 1 }?.gross, 7)
        XCTAssertTrue(s.undoLastEdit())
        XCTAssertEqual(s.currentRound.scores.first { $0.holeNumber == 1 }?.gross, 0)
    }
}
