import XCTest
@testable import GolfCore

final class AimAdvisorTests: XCTestCase {

    private let advisor = AimAdvisor()
    private let player = GeoCoordinate(latitude: 25.0, longitude: 121.0)

    func testGreenDistancesAreOrderedFrontToBack() {
        let green = GreenPoints(
            front:  GeoCoordinate(latitude: 25.0, longitude: 121.0010),
            center: GeoCoordinate(latitude: 25.0, longitude: 121.0015),
            back:   GeoCoordinate(latitude: 25.0, longitude: 121.0020)
        )
        let d = advisor.greenDistances(from: player, green: green)
        XCTAssertLessThan(d.frontYards, d.centerYards)
        XCTAssertLessThan(d.centerYards, d.backYards)
        XCTAssertEqual(d.frontYards, 110, accuracy: 12)
        XCTAssertEqual(d.backYards, 220, accuracy: 14)
    }

    func testHazardCarriesSortedWithClearedFlag() {
        let hazards = [
            GeoCoordinate(latitude: 25.0, longitude: 121.0030),  // far ~331 yd
            GeoCoordinate(latitude: 25.0, longitude: 121.0005)   // near ~55 yd
        ]
        let carries = advisor.hazardCarries(
            from: player, hazards: hazards, nominalShotYards: 150
        )
        XCTAssertEqual(carries.count, 2)
        XCTAssertLessThan(carries[0].carryYards, carries[1].carryYards) // nearest first
        XCTAssertTrue(carries[0].cleared)                                // 150 > ~55
        XCTAssertFalse(carries[1].cleared)                               // 150 < ~331
    }

    func testSuggestedLayupPicksLongestSafeClub() {
        let hazards = [GeoCoordinate(latitude: 25.0, longitude: 121.0015)] // ~165 yd
        let layup = advisor.suggestedLayupYards(
            from: player,
            hazards: hazards,
            clubCarriesYards: [80, 120, 160, 230],
            safetyMarginYards: 10
        )
        // ceiling ≈ 155 yd -> longest club ≤ ceiling is 120
        XCTAssertEqual(layup, 120)
    }

    func testSuggestedLayupNilWhenNoHazards() {
        XCTAssertNil(advisor.suggestedLayupYards(
            from: player, hazards: [], clubCarriesYards: [120, 150]
        ))
    }
}
