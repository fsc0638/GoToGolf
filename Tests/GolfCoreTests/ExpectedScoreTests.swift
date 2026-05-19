import XCTest
@testable import GolfCore

final class ExpectedScoreTests: XCTestCase {

    func testExpectedDifferentials() {
        // 1.04 * 10 + 0.4 = 10.8
        XCTAssertEqual(WHSEngine.expectedDifferential18(handicapIndex: 10), 10.8, accuracy: 0.0001)
        XCTAssertEqual(WHSEngine.expectedDifferential9(handicapIndex: 10), 5.4, accuracy: 0.0001)
    }

    func testNineHoleConvertsToEighteenSameDay() {
        // 8.0 played + expected 9-hole complement (5.4) = 13.4
        let d = WHSEngine.eighteenHoleDifferential(
            fromNineHole: 8.0, currentHandicapIndex: 10
        )
        XCTAssertEqual(d, 13.4, accuracy: 0.0001)
    }

    func testUnfinishedRoundFillsWithExpectedScore() throws {
        // 14 holes played, 4 missing. per-hole expected = 10.8/18 = 0.6
        // fill = 2.4 ; 10.0 + 2.4 = 12.4
        let d = WHSEngine.differentialForUnfinishedRound(
            holesPlayed: 14, playedDifferentialPortion: 10.0, currentHandicapIndex: 10
        )
        XCTAssertEqual(try XCTUnwrap(d), 12.4, accuracy: 0.0001)
    }

    func testUnfinishedRoundRejectsOutOfRange() {
        XCTAssertNil(WHSEngine.differentialForUnfinishedRound(
            holesPlayed: 9, playedDifferentialPortion: 5, currentHandicapIndex: 10))
        XCTAssertNil(WHSEngine.differentialForUnfinishedRound(
            holesPlayed: 18, playedDifferentialPortion: 10, currentHandicapIndex: 10))
    }
}
