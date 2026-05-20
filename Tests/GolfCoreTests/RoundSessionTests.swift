import XCTest
@testable import GolfCore

final class RoundSessionTests: XCTestCase {

    private func course() -> Course {
        let holes = (1...3).map { Hole(id: $0, par: 4, strokeIndex: $0) }
        return Course(
            id: "C", name: "Range Three",
            holes: holes,
            ratings: [.white: TeeRating(courseRating: 72, slopeRating: 113)]
        )
    }

    func testStartsOnFirstHoleWithEmptyCard() {
        let s = RoundSession(course: course(), teeBox: .white)
        XCTAssertEqual(s.currentHole, 1)
        XCTAssertEqual(s.currentRound.totalGross, 0)
        XCTAssertEqual(s.pendingSyncCount, 0)
    }

    func testSetGrossAndPuttsPerHoleQueuesSync() {
        let s = RoundSession(course: course(), teeBox: .white)
        XCTAssertTrue(s.setGross(5, hole: 1))
        XCTAssertTrue(s.setPutts(2, hole: 1))
        XCTAssertTrue(s.setGross(4, hole: 2))

        XCTAssertEqual(s.currentRound.scores.first { $0.holeNumber == 1 }?.gross, 5)
        XCTAssertEqual(s.currentRound.scores.first { $0.holeNumber == 1 }?.putts, 2)
        XCTAssertEqual(s.currentRound.scores.first { $0.holeNumber == 2 }?.gross, 4)
        XCTAssertEqual(s.pendingSyncCount, 3)
    }

    func testSelectHoleOnlyAcceptsValidHoles() {
        let s = RoundSession(course: course(), teeBox: .white)
        XCTAssertTrue(s.selectHole(2))
        XCTAssertEqual(s.currentHole, 2)
        XCTAssertFalse(s.selectHole(99))     // not in the course
        XCTAssertEqual(s.currentHole, 2)     // unchanged
    }

    func testFinishRoundMarksCompleted() {
        let s = RoundSession(course: course(), teeBox: .white)
        s.setGross(4, hole: 1)
        let finished = s.finishRound()
        XCTAssertEqual(finished.status, .completed)
        XCTAssertNotNil(finished.finishedAt)
    }

    func testDrainSyncFlushesPendingScoreUpdates() {
        let s = RoundSession(course: course(), teeBox: .white)
        s.setGross(4, hole: 1)
        s.setGross(5, hole: 2)
        var values: [Int] = []
        let sent = s.drainSync { values.append($0.value); return true }
        XCTAssertEqual(sent, 2)
        XCTAssertEqual(values, [4, 5])
        XCTAssertEqual(s.pendingSyncCount, 0)
    }
}
