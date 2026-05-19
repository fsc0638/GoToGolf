import XCTest
@testable import GolfCore

final class RoundReconcilerTests: XCTestCase {

    private let rec = RoundReconciler()

    private func synced(
        id: UUID,
        _ scores: [(Int, Int)],
        updatedAt: TimeInterval,
        status: RoundStatus = .inProgress,
        finishedAt: Date? = nil,
        device: String = "A"
    ) -> SyncedRound {
        let s = scores.map { HoleScore(holeNumber: $0.0, gross: $0.1) }
        let r = Round(
            id: id, courseID: "C", teeBox: .white,
            startedAt: Date(timeIntervalSince1970: 0),
            finishedAt: finishedAt, scores: s, pcc: 0, status: status
        )
        return SyncedRound(
            round: r, updatedAt: Date(timeIntervalSince1970: updatedAt), deviceID: device
        )
    }

    private func gross(_ sr: SyncedRound, hole: Int) -> Int? {
        sr.round.scores.first { $0.holeNumber == hole }?.gross
    }

    func testNoLocalReturnsRemoteUnchanged() {
        let remote = synced(id: UUID(), [(1, 4)], updatedAt: 10)
        XCTAssertEqual(rec.reconcile(local: nil, remote: remote), remote)
    }

    func testNewerPositiveEditWinsByLWW() {
        let id = UUID()
        let local = synced(id: id, [(1, 4)], updatedAt: 10)
        let remote = synced(id: id, [(1, 5)], updatedAt: 20)   // newer
        let merged = rec.reconcile(local: local, remote: remote)
        XCTAssertEqual(gross(merged, hole: 1), 5)
    }

    func testIntentionalCorrectionFollowsLWWNotMax() {
        let id = UUID()
        let local = synced(id: id, [(1, 7)], updatedAt: 100)   // newer, corrected down
        let remote = synced(id: id, [(1, 9)], updatedAt: 50)
        let merged = rec.reconcile(local: local, remote: remote)
        XCTAssertEqual(gross(merged, hole: 1), 7)   // not 9 — LWW, not blind max
    }

    /// Headline guarantee: a recorded stroke is never erased by a staler
    /// device syncing a 0, even though that device wrote last.
    func testStrokeProtectionBeatsStaleZero() {
        let id = UUID()
        let local = synced(id: id, [(1, 4), (2, 6)], updatedAt: 10)         // older
        let remote = synced(id: id, [(1, 4), (2, 0)], updatedAt: 50)        // newer, lost hole 2
        let merged = rec.reconcile(local: local, remote: remote)
        XCTAssertEqual(gross(merged, hole: 1), 4)
        XCTAssertEqual(gross(merged, hole: 2), 6)   // protected, not 0
    }

    func testCompletedNeverRevertsToInProgress() {
        let id = UUID()
        let local = synced(id: id, [(1, 4)], updatedAt: 10,
                           status: .completed, finishedAt: Date(timeIntervalSince1970: 9))
        let remote = synced(id: id, [(1, 4)], updatedAt: 99, status: .inProgress)
        let merged = rec.reconcile(local: local, remote: remote)
        XCTAssertEqual(merged.round.status, .completed)
        XCTAssertNotNil(merged.round.finishedAt)
    }

    func testBatchMergesExistingAddsNewKeepsLocalOnly() {
        let store = InMemoryRoundStore()
        let idX = UUID(), idY = UUID(), idZ = UUID()

        store.upsert(synced(id: idX, [(1, 3)], updatedAt: 10))   // will be merged
        store.upsert(synced(id: idZ, [(1, 2)], updatedAt: 10))   // local-only, untouched

        let incoming = [
            synced(id: idX, [(1, 5)], updatedAt: 20),            // newer edit
            synced(id: idY, [(1, 4)], updatedAt: 5)              // brand new
        ]
        let snapshot = rec.reconcile(store: store, incoming: incoming)

        XCTAssertEqual(snapshot.count, 3)
        XCTAssertEqual(gross(store.round(id: idX)!, hole: 1), 5)
        XCTAssertEqual(gross(store.round(id: idY)!, hole: 1), 4)
        XCTAssertEqual(gross(store.round(id: idZ)!, hole: 1), 2)

        // Re-pulling the same batch changes nothing.
        rec.reconcile(store: store, incoming: incoming)
        XCTAssertEqual(store.all().count, 3)
        XCTAssertEqual(gross(store.round(id: idX)!, hole: 1), 5)
    }
}
