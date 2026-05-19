import XCTest
@testable import GolfCore

final class PowerBudgetEstimatorTests: XCTestCase {

    private let est = PowerBudgetEstimator()

    func testProxyConfigMeetsPhase1KPI() {
        // proxy + AOD + low precise fraction over 4.5 h.
        // drain = 3.0 + (4.5*0.8) + (10*0.4) + (3*0.1) = 10.9 %/h
        // remaining = 100 - 49.05 = 50.95  (> 45 ✓)
        let remaining = est.remainingPercent(
            durationHours: 4.5, strategy: .bluetoothProxy,
            aodOptimized: true, preciseFraction: 0.1
        )
        XCTAssertEqual(remaining, 50.95, accuracy: 1e-9)
        XCTAssertTrue(est.meetsPhase1KPI(
            strategy: .bluetoothProxy, aodOptimized: true, preciseFraction: 0.1))
    }

    func testIndependentGPSFailsPhase1KPI() {
        // Why the proxy matters: watch GPS + bright screen drains too fast.
        XCTAssertFalse(est.meetsPhase1KPI(
            strategy: .watchGPS, aodOptimized: false, preciseFraction: 0.5))
    }

    func testProxyAlwaysBeatsIndependent() {
        let proxy = est.remainingPercent(
            durationHours: 4.5, strategy: .bluetoothProxy,
            aodOptimized: true, preciseFraction: 0.2)
        let independent = est.remainingPercent(
            durationHours: 4.5, strategy: .watchGPS,
            aodOptimized: true, preciseFraction: 0.2)
        XCTAssertGreaterThan(proxy, independent)
    }

    func testLongerRoundDrainsMore() {
        let short = est.remainingPercent(
            durationHours: 2, strategy: .bluetoothProxy,
            aodOptimized: true, preciseFraction: 0.1)
        let long = est.remainingPercent(
            durationHours: 4.5, strategy: .bluetoothProxy,
            aodOptimized: true, preciseFraction: 0.1)
        XCTAssertGreaterThan(short, long)
    }

    func testRemainingClampsAtZero() {
        let r = est.remainingPercent(
            durationHours: 20, strategy: .watchGPS,
            aodOptimized: false, preciseFraction: 1.0)
        XCTAssertEqual(r, 0, accuracy: 1e-9)
    }

    func testPreciseFractionIsClamped() {
        XCTAssertEqual(
            est.drainPerHour(strategy: .bluetoothProxy, aodOptimized: true, preciseFraction: 2.0),
            est.drainPerHour(strategy: .bluetoothProxy, aodOptimized: true, preciseFraction: 1.0),
            accuracy: 1e-9
        )
    }
}
