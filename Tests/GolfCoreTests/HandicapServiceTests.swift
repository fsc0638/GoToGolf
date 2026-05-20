import XCTest
@testable import GolfCore

final class HandicapServiceTests: XCTestCase {

    private let service = HandicapService()

    private func course(ratings: [TeeBox: TeeRating]) -> Course {
        let holes = (1...18).map { Hole(id: $0, par: 4, strokeIndex: $0) }
        return Course(id: "C", name: "T", holes: holes, ratings: ratings)
    }

    private func round(grossFirst n: Int, gross: Int, tee: TeeBox = .white) -> Round {
        Round(
            courseID: "C", teeBox: tee,
            scores: (1...n).map { HoleScore(holeNumber: $0, gross: gross) }
        )
    }

    private let standard: [TeeBox: TeeRating] = [
        .white: TeeRating(courseRating: 72.0, slopeRating: 113)
    ]

    func testEighteenHoleNoPriorHistory() throws {
        let s = try service.submit(
            round: round(grossFirst: 18, gross: 5),
            course: course(ratings: standard),
            priorDifferentials: [],
            currentHandicapIndex: 0
        )
        // AGS 90, (113/113)*(90-72) = 18.0
        XCTAssertEqual(s.differential, 18.0, accuracy: 1e-9)
        XCTAssertNil(s.newHandicapIndex)          // < 3 scores
        XCTAssertEqual(s.acceptedScoresCount, 1)
        XCTAssertEqual(s.mode, .eighteen)
    }

    func testEighteenHoleWithEstablishedHistory() throws {
        let s = try service.submit(
            round: round(grossFirst: 18, gross: 5),
            course: course(ratings: standard),
            priorDifferentials: [20.0, 22.0, 18.0],
            currentHandicapIndex: 16.0
        )
        XCTAssertEqual(s.differential, 18.0, accuracy: 1e-9)
        // history [20,22,18,18] -> selection(4): lowest 2 avg -1.0
        // (18+18)/2 - 1 = 17.0
        XCTAssertEqual(s.newHandicapIndex, 17.0)
        XCTAssertEqual(s.acceptedScoresCount, 4)
    }

    func testNineHoleSameDayUsesExpectedScore() throws {
        let s = try service.submit(
            round: round(grossFirst: 9, gross: 5),
            course: course(ratings: standard),
            priorDifferentials: [],
            currentHandicapIndex: 10.0
        )
        // 9-hole diff = (113/113)*(45 - 36) = 9.0
        // complement = expected9(10) = 5.4 ; total 14.4
        XCTAssertEqual(s.differential, 14.4, accuracy: 1e-9)
        XCTAssertEqual(s.mode, .nineHoleSameDay)
    }

    func testUnfinishedRoundFilledWithExpectedScore() throws {
        let s = try service.submit(
            round: round(grossFirst: 14, gross: 5),
            course: course(ratings: standard),
            priorDifferentials: [],
            currentHandicapIndex: 10.0
        )
        // portion = (113/113)*(70 - 56) = 14.0 ; fill = 0.6*4 = 2.4 ; 16.4
        XCTAssertEqual(s.differential, 16.4, accuracy: 1e-9)
        XCTAssertEqual(s.mode, .unfinished)
    }

    func testTooFewHolesThrows() {
        XCTAssertThrowsError(
            try service.submit(
                round: round(grossFirst: 5, gross: 5),
                course: course(ratings: standard),
                priorDifferentials: [],
                currentHandicapIndex: 0
            )
        ) { XCTAssertEqual($0 as? HandicapError, .tooFewHoles) }
    }

    func testMissingTeeRatingThrows() {
        XCTAssertThrowsError(
            try service.submit(
                round: round(grossFirst: 18, gross: 5, tee: .white),
                course: course(ratings: [.blue: TeeRating(courseRating: 70, slopeRating: 120)]),
                priorDifferentials: [],
                currentHandicapIndex: 0
            )
        ) { XCTAssertEqual($0 as? HandicapError, .noTeeRating) }
    }
}
