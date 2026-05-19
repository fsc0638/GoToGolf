import XCTest
@testable import GolfCore

final class GeofenceLockTests: XCTestCase {

    private let teeA = GeoCoordinate(latitude: 25.0000, longitude: 121.0000)
    private let teeB = GeoCoordinate(latitude: 25.0100, longitude: 121.0000) // ~1.1 km
    private let teeC = GeoCoordinate(latitude: 25.0200, longitude: 121.0000)

    private func makeLock() -> GeofenceLock {
        GeofenceLock(currentHole: 1, tees: [1: teeA, 2: teeB, 3: teeC])
    }

    func testStartsLocked() {
        let lock = makeLock()
        XCTAssertTrue(lock.isLocked)
        XCTAssertEqual(lock.tryAutoAdvance(now: 0), .blockedStillLocked)
        XCTAssertEqual(lock.currentHole, 1)
    }

    /// The headline anti-jump guarantee: brushing/raindrop noise while never
    /// dwelling in the next tee box must produce 0 hole changes.
    func testZeroFalseAutoAdvancesUnderNoise() {
        let lock = makeLock()
        var advances = 0
        for i in 0..<100 {
            let t = Double(i)
            lock.update(coordinate: teeA, now: t)        // never near hole 2
            if case .advanced = lock.tryAutoAdvance(now: t) { advances += 1 }
        }
        XCTAssertEqual(advances, 0)
        XCTAssertEqual(lock.currentHole, 1)
    }

    func testAutoAdvanceRequiresFullDwell() {
        let lock = makeLock()
        lock.update(coordinate: teeB, now: 1000)             // enter zone
        XCTAssertEqual(lock.tryAutoAdvance(now: 1005), .blockedStillLocked) // 5s
        XCTAssertEqual(lock.tryAutoAdvance(now: 1030), .advanced(toHole: 2)) // 30s
        XCTAssertEqual(lock.currentHole, 2)
    }

    func testLeavingZoneRestartsDwell() {
        let lock = makeLock()
        lock.update(coordinate: teeB, now: 0)     // enter
        lock.update(coordinate: teeA, now: 10)    // leave before 30s
        lock.update(coordinate: teeB, now: 20)    // re-enter, clock restarts
        XCTAssertEqual(lock.tryAutoAdvance(now: 45), .blockedStillLocked) // only 25s
        XCTAssertEqual(lock.tryAutoAdvance(now: 51), .advanced(toHole: 2)) // 31s
    }

    func testManualAdvanceRequiresValidSafeGesture() {
        let lock = makeLock()
        XCTAssertEqual(
            lock.manualAdvance(gesture: SafeGesture(twoFingerLongPress: false, swipe: true)),
            .rejectedInvalidGesture
        )
        XCTAssertEqual(lock.currentHole, 1)
        XCTAssertEqual(
            lock.manualAdvance(gesture: SafeGesture(twoFingerLongPress: true, swipe: true)),
            .advanced(toHole: 2)
        )
        XCTAssertEqual(lock.currentHole, 2)
    }

    func testManualJumpToArbitraryHole() {
        let lock = makeLock()
        let valid = SafeGesture(twoFingerLongPress: true, swipe: true)
        XCTAssertEqual(lock.manualJump(to: 3, gesture: valid), .advanced(toHole: 3))
        XCTAssertEqual(lock.currentHole, 3)
        XCTAssertEqual(
            lock.manualJump(to: 1, gesture: SafeGesture(twoFingerLongPress: true, swipe: false)),
            .rejectedInvalidGesture
        )
    }
}
