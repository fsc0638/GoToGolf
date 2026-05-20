import XCTest
@testable import GolfCore

final class ScorecardManagerTests: XCTestCase {

    private func course() -> Course {
        let holes = (1...3).map { Hole(id: $0, par: 4, strokeIndex: $0) }
        return Course(id: "C", name: "T", holes: holes,
                      ratings: [.white: TeeRating(courseRating: 72, slopeRating: 113)])
    }

    func testSeedsEmptyCard() {
        let mgr = ScorecardManager(round: Round(courseID: "C", teeBox: .white), course: course())
        XCTAssertEqual(mgr.score(for: 1)?.gross, 0)
        XCTAssertEqual(mgr.score(for: 3)?.gross, 0)
    }

    func testIncrementDecrementAndUndo() {
        let mgr = ScorecardManager(round: Round(courseID: "C", teeBox: .white), course: course())
        XCTAssertTrue(mgr.increment(hole: 1))
        XCTAssertTrue(mgr.increment(hole: 1))
        XCTAssertEqual(mgr.score(for: 1)?.gross, 2)
        XCTAssertTrue(mgr.decrement(hole: 1))
        XCTAssertEqual(mgr.score(for: 1)?.gross, 1)

        // One-action correction.
        XCTAssertTrue(mgr.canUndo)
        XCTAssertTrue(mgr.undo())
        XCTAssertEqual(mgr.score(for: 1)?.gross, 2)

        // Can't go below zero.
        let fresh = ScorecardManager(round: Round(courseID: "C", teeBox: .white), course: course())
        XCTAssertFalse(fresh.decrement(hole: 1))
    }

    func testTotalsAndToPar() {
        let mgr = ScorecardManager(round: Round(courseID: "C", teeBox: .white), course: course())
        mgr.setGross(2, hole: 1)   // par 4 -> -2
        mgr.setGross(5, hole: 2)   // par 4 -> +1
        XCTAssertEqual(mgr.totalGross, 7)
        XCTAssertEqual(mgr.totalToPar, -1)   // hole 3 unplayed, ignored
    }

    func testAdjustedGrossScoreUsesCap() {
        let mgr = ScorecardManager(round: Round(courseID: "C", teeBox: .white), course: course())
        mgr.setGross(12, hole: 1)
        mgr.setGross(5, hole: 2)
        mgr.setGross(4, hole: 3)
        // Beginner cap = 9: 9 + 5 + 4 = 18
        XCTAssertEqual(mgr.adjustedGrossScore(establishedCourseHandicap: nil), 18)
        // CH 3 over 3 holes -> NDB 7: 7 + 5 + 4 = 16
        XCTAssertEqual(mgr.adjustedGrossScore(establishedCourseHandicap: 3), 16)
    }
}
