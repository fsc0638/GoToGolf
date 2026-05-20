import XCTest
@testable import GolfCore

final class RoundAnalyzerTests: XCTestCase {

    private func course() -> Course {
        let holes = (1...9).map { Hole(id: $0, par: 4, strokeIndex: $0) }
        return Course(id: "C", name: "Nine", holes: holes,
                      ratings: [.white: TeeRating(courseRating: 35, slopeRating: 113)])
    }

    private func round() -> Round {
        // hole: (gross, putts) — par is 4 throughout
        let data: [(Int, Int, Int)] = [
            (1, 3, 1),  // birdie, GIR (2≤2), 1-putt
            (2, 4, 2),  // par,    GIR (2≤2)
            (3, 5, 2),  // bogey,  not GIR (3)
            (4, 2, 1),  // eagle,  GIR (1≤2), 1-putt
            (5, 6, 3),  // double, not GIR, 3-putt
            (6, 7, 2),  // triple, not GIR
            (7, 4, 2),  // par,    GIR (2≤2)
            (8, 4, 1),  // par,    not GIR (3), 1-putt
            (9, 0, 0)   // not played — ignored
        ]
        return Round(
            courseID: "C", teeBox: .white,
            scores: data.map { HoleScore(holeNumber: $0.0, gross: $0.1, putts: $0.2) }
        )
    }

    func testAnalyzeProducesCorrectStats() {
        let s = RoundAnalyzer.analyze(round: round(), course: course())

        XCTAssertEqual(s.holesPlayed, 8)
        XCTAssertEqual(s.totalGross, 35)
        XCTAssertEqual(s.totalPutts, 14)
        XCTAssertEqual(s.totalToPar, 3)

        XCTAssertEqual(s.eaglesOrBetter, 1)
        XCTAssertEqual(s.birdies, 1)
        XCTAssertEqual(s.pars, 3)
        XCTAssertEqual(s.bogeys, 1)
        XCTAssertEqual(s.doubleBogeys, 1)
        XCTAssertEqual(s.triplesOrWorse, 1)
        XCTAssertEqual(
            s.eaglesOrBetter + s.birdies + s.pars + s.bogeys
                + s.doubleBogeys + s.triplesOrWorse,
            s.holesPlayed
        )

        XCTAssertEqual(s.greensInRegulation, 4)   // holes 1,2,4,7
        XCTAssertEqual(s.onePutts, 3)             // holes 1,4,8
        XCTAssertEqual(s.threePuttsOrWorse, 1)    // hole 5
        XCTAssertEqual(s.averagePuttsPerHole, 1.75, accuracy: 1e-9)
    }

    func testEmptyRoundIsAllZero() {
        let empty = Round(courseID: "C", teeBox: .white, scores: [])
        let s = RoundAnalyzer.analyze(round: empty, course: course())
        XCTAssertEqual(s.holesPlayed, 0)
        XCTAssertEqual(s.totalGross, 0)
        XCTAssertEqual(s.averagePuttsPerHole, 0)
    }
}
