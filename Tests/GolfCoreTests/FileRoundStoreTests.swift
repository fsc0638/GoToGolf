import XCTest
@testable import GolfCore

final class FileRoundStoreTests: XCTestCase {

    private var url: URL!

    override func setUp() {
        super.setUp()
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("rounds-\(UUID().uuidString).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: url)
        super.tearDown()
    }

    private func synced(_ id: UUID, hole1 gross: Int, updatedAt: TimeInterval) -> SyncedRound {
        SyncedRound(
            round: Round(id: id, courseID: "C", teeBox: .white,
                         startedAt: Date(timeIntervalSince1970: 0),
                         scores: [HoleScore(holeNumber: 1, gross: gross)]),
            updatedAt: Date(timeIntervalSince1970: updatedAt),
            deviceID: "test")
    }

    func testCrudAndOrdering() {
        let store = FileRoundStore(fileURL: url)
        let a = synced(UUID(), hole1: 4, updatedAt: 10)
        let b = synced(UUID(), hole1: 5, updatedAt: 20)
        store.upsert(a)
        store.upsert(b)
        XCTAssertEqual(store.all().count, 2)
        XCTAssertEqual(store.round(id: a.id)?.round.scores.first?.gross, 4)
        store.delete(id: a.id)
        XCTAssertNil(store.round(id: a.id))
        XCTAssertEqual(store.all().count, 1)
    }

    func testSurvivesReload() {
        let id = UUID()
        do {
            let store = FileRoundStore(fileURL: url)
            store.upsert(synced(id, hole1: 7, updatedAt: 10))
        }
        // Fresh instance, same file.
        let reloaded = FileRoundStore(fileURL: url)
        XCTAssertEqual(reloaded.round(id: id)?.round.scores.first?.gross, 7)
    }

    /// End-to-end #2 closure: a CloudKit-style pull reconciled into the
    /// file store is persisted and survives reload, with stroke protection.
    func testReconcilerIntegrationPersists() {
        let id = UUID()
        let store = FileRoundStore(fileURL: url)
        // Local (older) recorded a 6 on hole 1.
        store.upsert(synced(id, hole1: 6, updatedAt: 10))
        // Remote (newer) lost hole 1 (0) — must NOT erase the recorded 6.
        let remote = synced(id, hole1: 0, updatedAt: 50)

        RoundReconciler().reconcile(store: store, incoming: [remote])

        XCTAssertEqual(store.round(id: id)?.round.scores.first?.gross, 6)
        let reloaded = FileRoundStore(fileURL: url)
        XCTAssertEqual(reloaded.round(id: id)?.round.scores.first?.gross, 6)
    }
}
