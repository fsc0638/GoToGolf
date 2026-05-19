import XCTest
@testable import GolfCore

final class GeoCoordinateTests: XCTestCase {

    func testDistanceToSelfIsZero() {
        let p = GeoCoordinate(latitude: 25, longitude: 121)
        XCTAssertEqual(p.distanceMeters(to: p), 0, accuracy: 0.0001)
    }

    func testDistanceIsSymmetricAndReasonable() {
        let a = GeoCoordinate(latitude: 25.0000, longitude: 121.0000)
        let b = GeoCoordinate(latitude: 25.0000, longitude: 121.0010)
        let ab = a.distanceMeters(to: b)
        let ba = b.distanceMeters(to: a)
        XCTAssertEqual(ab, ba, accuracy: 0.0001)
        // ~0.001 deg lon at lat 25 ≈ 100 m
        XCTAssertGreaterThan(ab, 90)
        XCTAssertLessThan(ab, 115)
    }

    func testYardsConversion() {
        let a = GeoCoordinate(latitude: 25, longitude: 121)
        let b = GeoCoordinate(latitude: 25.001, longitude: 121)
        XCTAssertEqual(a.distanceYards(to: b),
                       a.distanceMeters(to: b) / 0.9144, accuracy: 0.0001)
    }

    func testBearingCardinalDirections() {
        let origin = GeoCoordinate(latitude: 25, longitude: 121)
        let east = GeoCoordinate(latitude: 25, longitude: 121.01)
        let north = GeoCoordinate(latitude: 25.01, longitude: 121)
        XCTAssertEqual(origin.bearingDegrees(to: east), 90, accuracy: 1.0)
        let nb = origin.bearingDegrees(to: north)
        XCTAssertTrue(nb < 1.0 || nb > 359.0, "north bearing was \(nb)")
    }
}
