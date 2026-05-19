import XCTest
@testable import GolfCore

final class WHSEngineTests: XCTestCase {

    func testScoreDifferentialFormula() {
        // (113/125) * (90 - 72.1 - 0) = 16.1816 -> 16.2
        let sd = WHSEngine.scoreDifferential(
            adjustedGrossScore: 90, courseRating: 72.1, slopeRating: 125
        )
        XCTAssertEqual(sd, 16.2, accuracy: 0.0001)
    }

    func testScoreDifferentialAppliesPCC() {
        // (113/125) * (90 - 72.1 - 1.0) = 15.2776 -> 15.3
        let sd = WHSEngine.scoreDifferential(
            adjustedGrossScore: 90, courseRating: 72.1, slopeRating: 125, pcc: 1.0
        )
        XCTAssertEqual(sd, 15.3, accuracy: 0.0001)
    }

    func testNetDoubleBogeyAndBeginnerCap() {
        XCTAssertEqual(WHSEngine.netDoubleBogey(par: 4, strokesReceived: 1), 7)
        XCTAssertEqual(WHSEngine.netDoubleBogey(par: 3, strokesReceived: 0), 5)
        XCTAssertEqual(WHSEngine.beginnerMaxScore(par: 4), 9)
        XCTAssertEqual(WHSEngine.beginnerMaxScore(par: 5), 10)
    }

    func testCourseHandicap() {
        // 18 * 125/113 + (72.1 - 72) = 20.01 -> 20
        XCTAssertEqual(
            WHSEngine.courseHandicap(handicapIndex: 18.0, slopeRating: 125,
                                     courseRating: 72.1, par: 72),
            20
        )
        XCTAssertEqual(
            WHSEngine.courseHandicap(handicapIndex: 0.0, slopeRating: 125,
                                     courseRating: 72.1, par: 72),
            0
        )
    }

    func testStrokesReceivedDistribution() {
        // CH 20 over 18 holes: everyone gets 1, two hardest get 2.
        XCTAssertEqual(WHSEngine.strokesReceived(courseHandicap: 20, strokeIndex: 1), 2)
        XCTAssertEqual(WHSEngine.strokesReceived(courseHandicap: 20, strokeIndex: 2), 2)
        XCTAssertEqual(WHSEngine.strokesReceived(courseHandicap: 20, strokeIndex: 3), 1)
        XCTAssertEqual(WHSEngine.strokesReceived(courseHandicap: 20, strokeIndex: 18), 1)
        XCTAssertEqual(WHSEngine.strokesReceived(courseHandicap: 0, strokeIndex: 1), 0)
        XCTAssertEqual(WHSEngine.strokesReceived(courseHandicap: 9, strokeIndex: 9), 1)
        XCTAssertEqual(WHSEngine.strokesReceived(courseHandicap: 9, strokeIndex: 10), 0)
    }

    private func threeHoleCourse() -> Course {
        let g = GreenPoints(
            front: GeoCoordinate(latitude: 25, longitude: 121),
            center: GeoCoordinate(latitude: 25, longitude: 121),
            back: GeoCoordinate(latitude: 25, longitude: 121)
        )
        let holes = (1...3).map {
            Hole(id: $0, par: 4, strokeIndex: $0,
                 tee: GeoCoordinate(latitude: 25, longitude: 121), green: g)
        }
        return Course(id: "C1", name: "Test", holes: holes,
                      ratings: [.white: TeeRating(courseRating: 72.1, slopeRating: 125)])
    }

    func testAdjustedGrossScoreBeginnerVsEstablished() {
        let course = threeHoleCourse()
        let round = Round(
            courseID: course.id, teeBox: .white,
            scores: [
                HoleScore(holeNumber: 1, gross: 12),
                HoleScore(holeNumber: 2, gross: 5),
                HoleScore(holeNumber: 3, gross: 4)
            ]
        )

        // Beginner cap = Par + 5 = 9: 9 + 5 + 4 = 18
        let beginner = WHSEngine.adjustedGrossScore(
            round: round, course: course, establishedCourseHandicap: nil
        )
        XCTAssertEqual(beginner, 18)

        // Established CH 3 over 3 holes -> 1 stroke each -> NDB = 4+2+1 = 7
        // 7 + 5 + 4 = 16
        let established = WHSEngine.adjustedGrossScore(
            round: round, course: course, establishedCourseHandicap: 3
        )
        XCTAssertEqual(established, 16)
    }
}
