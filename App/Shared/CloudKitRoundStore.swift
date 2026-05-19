import Foundation
import CloudKit
import GolfCore

/// CloudKit-backed `RoundStore`.
///
/// ⚠️ COMPILE-ONLY IN THIS ENVIRONMENT. The code builds (CloudKit links
/// without entitlements) but its CloudKit operations CANNOT be exercised
/// here: they require the `com.apple.developer.icloud-services`
/// entitlement, a signed build, and a signed-in iCloud account on a real
/// device. The unsigned simulator CI path (`CODE_SIGNING_ALLOWED=NO`)
/// reaches none of that. Runtime sync must be validated on device.
///
/// Architecture: the synchronous `RoundStore` API is served immediately by
/// a local `FileRoundStore` (source of truth for the UI). CloudKit is an
/// eventual mirror — writes are pushed in the background; `pull()` fetches
/// remote records and merges them through the tested `RoundReconciler`
/// (Last-Write-Wins + stroke protection), so a stale device can never
/// erase a recorded score. This is the same protocol the app already uses
/// via `FileRoundStore`, so swapping stores changes nothing downstream.
final class CloudKitRoundStore: RoundStore {
    private let local: FileRoundStore
    private let database: CKDatabase
    private let reconciler = RoundReconciler()
    private let recordType = "Round"
    private let zoneID = CKRecordZone.ID(zoneName: "Rounds", ownerName: CKCurrentUserDefaultName)

    init(localFileURL: URL,
         container: CKContainer = .default()) {
        self.local = FileRoundStore(fileURL: localFileURL)
        self.database = container.privateCloudDatabase
    }

    // MARK: RoundStore (synchronous — served by the local cache)

    func upsert(_ record: SyncedRound) {
        local.upsert(record)
        Task { await pushToCloud(record) }
    }

    func round(id: UUID) -> SyncedRound? {
        local.round(id: id)
    }

    func all() -> [SyncedRound] {
        local.all()
    }

    func delete(id: UUID) {
        local.delete(id: id)
        Task { await deleteFromCloud(id) }
    }

    // MARK: CloudKit mirror (eventual; unverified here)

    private func ckRecordID(_ id: UUID) -> CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
    }

    private func pushToCloud(_ record: SyncedRound) async {
        guard let payload = try? JSONEncoder().encode(record) else { return }
        let ck = CKRecord(recordType: recordType, recordID: ckRecordID(record.id))
        ck["payload"] = payload as CKRecordValue
        ck["updatedAt"] = record.updatedAt as CKRecordValue
        _ = try? await database.save(ck)
    }

    private func deleteFromCloud(_ id: UUID) async {
        _ = try? await database.deleteRecord(withID: ckRecordID(id))
    }

    /// Pull remote rounds and merge them into the local store via the
    /// tested reconciler. Call on launch / foreground / push notification.
    func pull() async {
        let query = CKQuery(recordType: recordType,
                            predicate: NSPredicate(value: true))
        guard let result = try? await database.records(matching: query) else { return }

        var incoming: [SyncedRound] = []
        for (_, recordResult) in result.matchResults {
            guard case .success(let record) = recordResult,
                  let data = record["payload"] as? Data,
                  let synced = try? JSONDecoder().decode(SyncedRound.self, from: data)
            else { continue }
            incoming.append(synced)
        }
        reconciler.reconcile(store: local, incoming: incoming)
    }
}
