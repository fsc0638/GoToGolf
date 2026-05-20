import XCTest
@testable import GolfCore

final class WatchSyncProtocolTests: XCTestCase {

    private func ctx(_ hole: Int, rev: Int) -> WatchContext {
        WatchContext(currentHole: hole, revision: rev)
    }

    func testApplicationContextKeepsOnlyNewestRevision() {
        let channel = ApplicationContextChannel()
        channel.push(ctx(1, rev: 1))
        channel.push(ctx(3, rev: 3))
        channel.push(ctx(2, rev: 2))   // out-of-order, stale
        XCTAssertEqual(channel.latest?.revision, 3)
        XCTAssertEqual(channel.latest?.currentHole, 3)
    }

    func testEnvelopeRoundTrips() throws {
        let env = SyncEnvelope(channel: .applicationContext, payload: ctx(5, rev: 9))
        let data = try JSONEncoder().encode(env)
        let decoded = try JSONDecoder().decode(
            SyncEnvelope<WatchContext>.self, from: data
        )
        XCTAssertEqual(decoded.channel, .applicationContext)
        XCTAssertEqual(decoded.payload, ctx(5, rev: 9))
    }

    /// Reconnect with a newer context moves the hole (authoritative phone
    /// state), so the watch can never be stranded on the wrong hole.
    func testNewerContextSnapsHoleOnReconnect() {
        let r = ContextReconciler()
        let local = HoleStateSnapshot(hole: 2, revision: 5)
        let merged = r.reconcile(local: local, incoming: ctx(7, rev: 8))
        XCTAssertEqual(merged, HoleStateSnapshot(hole: 7, revision: 8))
    }

    /// A stale context must NOT drag the hole backward — this is the
    /// systemic anti-jump guarantee.
    func testStaleContextCannotMoveHole() {
        let r = ContextReconciler()
        let local = HoleStateSnapshot(hole: 6, revision: 10)
        XCTAssertEqual(r.reconcile(local: local, incoming: ctx(1, rev: 3)), local)
        XCTAssertEqual(r.reconcile(local: local, incoming: ctx(9, rev: 10)), local) // tie
    }
}
