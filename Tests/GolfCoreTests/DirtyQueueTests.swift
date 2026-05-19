import XCTest
@testable import GolfCore

final class DirtyQueueTests: XCTestCase {

    private func update(_ hole: Int) -> ScoreUpdate {
        ScoreUpdate(holeNumber: hole, kind: .setGross, value: 4)
    }

    func testEnqueuePreservesOrder() {
        let q = DirtyQueue<ScoreUpdate>()
        let a = update(1), b = update(2), c = update(3)
        q.enqueue(a); q.enqueue(b); q.enqueue(c)
        XCTAssertEqual(q.count, 3)
        XCTAssertEqual(q.pending.map(\.holeNumber), [1, 2, 3])
    }

    func testEnqueueIsIdempotentByID() {
        let q = DirtyQueue<ScoreUpdate>()
        let a = ScoreUpdate(holeNumber: 1, kind: .setGross, value: 4)
        let aRetry = ScoreUpdate(id: a.id, holeNumber: 1, kind: .setGross, value: 5)
        q.enqueue(a)
        q.enqueue(update(2))
        q.enqueue(aRetry)                         // same id -> replace in place
        XCTAssertEqual(q.count, 2)
        XCTAssertEqual(q.pending.first?.value, 5) // updated, position kept
        XCTAssertEqual(q.pending.map(\.holeNumber), [1, 2])
    }

    func testDrainStopsAtFirstFailureAndKeepsOrder() {
        let q = DirtyQueue<ScoreUpdate>()
        [1, 2, 3].forEach { q.enqueue(update($0)) }

        var allowed = 1
        let delivered = q.drain { _ in
            if allowed > 0 { allowed -= 1; return true }
            return false
        }
        XCTAssertEqual(delivered, 1)
        XCTAssertEqual(q.pending.map(\.holeNumber), [2, 3]) // intact, in order

        let rest = q.drain { _ in true }
        XCTAssertEqual(rest, 2)
        XCTAssertTrue(q.isEmpty)
    }

    func testTotalDisconnectDeliversNothing() {
        let q = DirtyQueue<ScoreUpdate>()
        [1, 2, 3].forEach { q.enqueue(update($0)) }
        let delivered = q.drain { _ in false }
        XCTAssertEqual(delivered, 0)
        XCTAssertEqual(q.count, 3)
    }

    func testPersistenceRoundTrip() throws {
        let q = DirtyQueue<ScoreUpdate>()
        [1, 2, 3].forEach { q.enqueue(update($0)) }
        let blob = try q.serialized()

        let restored = DirtyQueue<ScoreUpdate>()
        try restored.restore(from: blob)
        XCTAssertEqual(restored.pending, q.pending)
    }

    /// Phase-3 acceptance scenario: Bluetooth flaps repeatedly across an
    /// 18-hole round. Every stroke must arrive exactly once, in hole order,
    /// with zero loss — 100% scorecard consistency.
    func testEighteenHoleFlappingConnectionIsLossless() {
        let q = DirtyQueue<ScoreUpdate>()
        var originalIDs: [UUID] = []
        for hole in 1...18 {
            let u = update(hole)
            q.enqueue(u)
            originalIDs.append(u.id)
        }

        var deliveredIDs: [UUID] = []
        var cycles = 0
        while !q.isEmpty {
            cycles += 1
            // Connection survives only ~3 sends before dropping mid-flush.
            var budget = 3
            q.drain { item in
                guard budget > 0 else { return false }
                budget -= 1
                deliveredIDs.append(item.id)
                return true
            }
            if cycles > 50 { break }   // safety, must never hit
        }

        XCTAssertEqual(deliveredIDs, originalIDs)   // order + no dup + no loss
        XCTAssertTrue(q.isEmpty)
        XCTAssertLessThanOrEqual(cycles, 7)         // 18 / 3 = 6 (+1 slack)
    }
}
