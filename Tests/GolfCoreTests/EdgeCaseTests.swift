import XCTest
@testable import GolfCore

/// Boundary cases that cut across the remaining (scoring-only) modules.
final class EdgeCaseTests: XCTestCase {

    func testHandicapRollingWindowAtTwentyOne() {
        // 21 scores: the single oldest, unrealistically-low score is
        // outside the most-recent-20 window and must be ignored.
        let diffs = [0.5] + Array(repeating: 5.0, count: 20)
        XCTAssertEqual(WHSEngine.handicapIndex(from: diffs), 5.0)
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
}
