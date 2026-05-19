import XCTest
@testable import GolfCore

/// Boundary cases that cut across modules — the corners most likely to
/// regress when the framework adapters are wired up later.
final class EdgeCaseTests: XCTestCase {

    func testHandicapRollingWindowAtTwentyOne() {
        // 21 scores: the single oldest, unrealistically-low score is
        // outside the most-recent-20 window and must be ignored.
        let diffs = [0.5] + Array(repeating: 5.0, count: 20)
        XCTAssertEqual(WHSEngine.handicapIndex(from: diffs), 5.0)
    }

    func testGeofenceLastHoleHasNoNext() {
        let lock = GeofenceLock(
            currentHole: 1,
            tees: [1: GeoCoordinate(latitude: 25, longitude: 121)]
        )
        XCTAssertEqual(lock.tryAutoAdvance(now: 999), .noNextHole)
        XCTAssertEqual(
            lock.manualAdvance(gesture: SafeGesture(twoFingerLongPress: true, swipe: true)),
            .noNextHole
        )
    }

    func testSwingConfirmWithoutTentativeIsNil() {
        let d = SwingDetector()
        XCTAssertNil(d.confirm(displacementMeters: 50, at: 1.0))
        XCTAssertFalse(d.isAwaitingDisplacementConfirmation)
    }

    func testDirtyQueueDrainWhenEmpty() {
        let q = DirtyQueue<ScoreUpdate>()
        XCTAssertEqual(q.drain { _ in true }, 0)
        XCTAssertTrue(q.isEmpty)
    }

    func testReconcilerHandlesBothEmptyScores() {
        let id = UUID()
        func sr(_ t: TimeInterval) -> SyncedRound {
            SyncedRound(
                round: Round(id: id, courseID: "C", teeBox: .white, scores: []),
                updatedAt: Date(timeIntervalSince1970: t), deviceID: "d"
            )
        }
        let merged = RoundReconciler().reconcile(local: sr(10), remote: sr(20))
        XCTAssertTrue(merged.round.scores.isEmpty)
        XCTAssertEqual(merged.updatedAt, Date(timeIntervalSince1970: 20))
    }

    func testUnfinishedRoundInclusiveBounds() {
        XCTAssertNotNil(WHSEngine.differentialForUnfinishedRound(
            holesPlayed: 10, playedDifferentialPortion: 10, currentHandicapIndex: 10))
        XCTAssertNotNil(WHSEngine.differentialForUnfinishedRound(
            holesPlayed: 17, playedDifferentialPortion: 10, currentHandicapIndex: 10))
        XCTAssertNil(WHSEngine.differentialForUnfinishedRound(
            holesPlayed: 8, playedDifferentialPortion: 10, currentHandicapIndex: 10))
    }

    func testWindWithZeroSpeedIsNeutral() {
        let e = WindCompensationEngine().effect(
            windSpeedMS: 0, windFromDegrees: 0,
            shotBearingDegrees: 0, nominalDistanceYards: 150
        )
        XCTAssertEqual(e.distanceDeltaYards, 0, accuracy: 1e-9)
        XCTAssertEqual(e.clubChange, 0)
    }

    func testAimAdvisorEmptyHazards() {
        let a = AimAdvisor()
        let p = GeoCoordinate(latitude: 25, longitude: 121)
        XCTAssertTrue(a.hazardCarries(from: p, hazards: [], nominalShotYards: 150).isEmpty)
        XCTAssertNil(a.suggestedLayupYards(from: p, hazards: [], clubCarriesYards: [120]))
    }
}
