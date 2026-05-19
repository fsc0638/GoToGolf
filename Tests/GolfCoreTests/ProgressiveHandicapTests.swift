import XCTest
@testable import GolfCore

final class ProgressiveHandicapTests: XCTestCase {

    func testNoHandicapBelowThreeRounds() {
        XCTAssertNil(WHSEngine.handicapIndex(from: []))
        XCTAssertNil(WHSEngine.handicapIndex(from: [10.0]))
        XCTAssertNil(WHSEngine.handicapIndex(from: [10.0, 12.0]))
    }

    func testThreeRoundsUsesLowestMinusTwo() {
        // lowest 1 of [14,10,12] = 10, adjustment -2.0 -> 8.0
        XCTAssertEqual(WHSEngine.handicapIndex(from: [14, 10, 12]), 8.0)
    }

    func testFourToSixRoundsLowestTwoMinusOne() {
        // lowest 2 of [16,10,14,12] = (10+12)/2 = 11, -1.0 -> 10.0
        XCTAssertEqual(WHSEngine.handicapIndex(from: [16, 10, 14, 12]), 10.0)
    }

    func testSevenRoundsLowestTwoNoAdjustment() {
        // lowest 2 of [5,6,7,8,9,10,11] = 5.5, no adjustment
        XCTAssertEqual(WHSEngine.handicapIndex(from: [5, 6, 7, 8, 9, 10, 11]), 5.5)
    }

    func testSelectionTableBoundaries() {
        XCTAssertEqual(WHSEngine.selection(forRoundCount: 3),
                       .init(lowestCount: 1, adjustment: -2.0))
        XCTAssertEqual(WHSEngine.selection(forRoundCount: 6),
                       .init(lowestCount: 2, adjustment: -1.0))
        XCTAssertEqual(WHSEngine.selection(forRoundCount: 9),
                       .init(lowestCount: 3, adjustment: 0))
        XCTAssertEqual(WHSEngine.selection(forRoundCount: 19),
                       .init(lowestCount: 7, adjustment: 0))
        XCTAssertEqual(WHSEngine.selection(forRoundCount: 25),
                       .init(lowestCount: 8, adjustment: 0))
        XCTAssertNil(WHSEngine.selection(forRoundCount: 2))
    }

    func testTwentyRoundsBestEightAverage() {
        // 12 x 8.0 + 8 x 4.0 -> best 8 = 4.0
        let diffs = Array(repeating: 8.0, count: 12) + Array(repeating: 4.0, count: 8)
        XCTAssertEqual(WHSEngine.handicapIndex(from: diffs), 4.0)
    }

    func testRollingWindowIgnoresOldRounds() {
        // First 5 are unrealistically low; only the most recent 20 count.
        let diffs = Array(repeating: 1.0, count: 5) + Array(repeating: 10.0, count: 20)
        XCTAssertEqual(WHSEngine.handicapIndex(from: diffs), 10.0)
    }
}
