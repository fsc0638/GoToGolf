import XCTest
@testable import GolfCore

final class LocationLogicTests: XCTestCase {

    // MARK: ProxyLocationDecider

    func testNoLinkForcesWatchGPS() {
        let d = ProxyLocationDecider()
        XCTAssertEqual(d.strategy(rssi: nil, current: .bluetoothProxy), .watchGPS)
    }

    func testStrongSignalDelegatesToPhone() {
        let d = ProxyLocationDecider()
        XCTAssertEqual(d.strategy(rssi: -65, current: .watchGPS), .bluetoothProxy)
    }

    func testWeakSignalStaysOnWatchGPS() {
        let d = ProxyLocationDecider()
        XCTAssertEqual(d.strategy(rssi: -75, current: .watchGPS), .watchGPS)
    }

    func testHysteresisAvoidsFlapping() {
        let d = ProxyLocationDecider()
        // In proxy mode, -75 is between thresholds -> hold proxy.
        XCTAssertEqual(d.strategy(rssi: -75, current: .bluetoothProxy), .bluetoothProxy)
        // Drop below disconnect threshold -> fall back to watch GPS.
        XCTAssertEqual(d.strategy(rssi: -85, current: .bluetoothProxy), .watchGPS)
    }

    // MARK: DynamicAccuracyController

    func testAccuracyTiers() {
        let c = DynamicAccuracyController()
        XCTAssertEqual(c.tier(distanceToGreenYards: 200, isStationary: false), .coarse)
        XCTAssertEqual(c.tier(distanceToGreenYards: 200, isStationary: true), .coarse)
        XCTAssertEqual(c.tier(distanceToGreenYards: 100, isStationary: false), .standard)
        XCTAssertEqual(c.tier(distanceToGreenYards: 40, isStationary: false), .standard)
        XCTAssertEqual(c.tier(distanceToGreenYards: 40, isStationary: true), .precise)
        XCTAssertEqual(c.tier(distanceToGreenYards: 50, isStationary: true), .precise)
        XCTAssertEqual(c.tier(distanceToGreenYards: 150, isStationary: true), .standard)
    }

    func testSampleIntervalsMatchTiers() {
        XCTAssertEqual(LocationAccuracyTier.coarse.sampleInterval, 10)
        XCTAssertEqual(LocationAccuracyTier.standard.sampleInterval, 5)
        XCTAssertEqual(LocationAccuracyTier.precise.sampleInterval, 1)
    }
}
