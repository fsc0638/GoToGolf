import XCTest
@testable import GolfCore

final class WindCompensationTests: XCTestCase {

    private let engine = WindCompensationEngine()

    func testPureHeadwindCostsDistance() {
        // Wind from N, shot due N -> 10 m/s headwind on a 150 yd shot.
        // 10 * 2.6 * 1.0 = 26 yards short.
        let e = engine.effect(
            windSpeedMS: 10, windFromDegrees: 0,
            shotBearingDegrees: 0, nominalDistanceYards: 150
        )
        XCTAssertEqual(e.distanceDeltaYards, -26.0, accuracy: 0.0001)
        XCTAssertEqual(e.relation, .headwind)
        XCTAssertEqual(e.clubChange, 2)
        XCTAssertTrue(e.advice.contains("逆風"))
    }

    func testPureTailwindAddsDistance() {
        // Wind from S, shot due N -> 10 m/s tailwind.
        // 10 * 1.8 * 1.0 = 18 yards long.
        let e = engine.effect(
            windSpeedMS: 10, windFromDegrees: 180,
            shotBearingDegrees: 0, nominalDistanceYards: 150
        )
        XCTAssertEqual(e.distanceDeltaYards, 18.0, accuracy: 0.0001)
        XCTAssertEqual(e.relation, .tailwind)
        XCTAssertEqual(e.clubChange, -1)
        XCTAssertTrue(e.advice.contains("順風"))
    }

    func testCrosswindIsMostlyLateral() {
        // Wind from E, shot due N -> pure crosswind, ~no distance change.
        let e = engine.effect(
            windSpeedMS: 10, windFromDegrees: 90,
            shotBearingDegrees: 0, nominalDistanceYards: 150
        )
        XCTAssertEqual(e.relation, .crosswind)
        XCTAssertEqual(e.clubChange, 0)
        XCTAssertLessThan(abs(e.distanceDeltaYards), 0.5)
        XCTAssertTrue(e.advice.contains("側風"))
    }

    func testEffectScalesWithShotDistance() {
        // Same 10 m/s headwind but a 75 yd shot -> half the penalty.
        let e = engine.effect(
            windSpeedMS: 10, windFromDegrees: 0,
            shotBearingDegrees: 0, nominalDistanceYards: 75
        )
        XCTAssertEqual(e.distanceDeltaYards, -13.0, accuracy: 0.0001)
        XCTAssertEqual(e.clubChange, 1)
    }

    func testCalmWindNeedsNoClubChange() {
        let e = engine.effect(
            windSpeedMS: 1, windFromDegrees: 0,
            shotBearingDegrees: 0, nominalDistanceYards: 150
        )
        XCTAssertEqual(e.clubChange, 0)
    }
}
