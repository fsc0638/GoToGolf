import Foundation

/// JSON-on-disk `RoundStore`. Survives app launches with no CloudKit
/// entitlement, and is the concrete store `RoundReconciler` merges remote
/// pulls into. The real `NSPersistentCloudKitContainer` can later conform to
/// the same protocol without touching the merge logic.
public final class FileRoundStore: RoundStore {
    private let fileURL: URL
    private var records: [UUID: SyncedRound] = [:]

    public init(fileURL: URL) {
        self.fileURL = fileURL
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let list = try? JSONDecoder().decode([SyncedRound].self, from: data)
        else { return }
        records = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(all()) else { return }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }

    public func upsert(_ record: SyncedRound) {
        records[record.id] = record
        persist()
    }

    public func round(id: UUID) -> SyncedRound? {
        records[id]
    }

    public func all() -> [SyncedRound] {
        records.values.sorted {
            if $0.round.startedAt != $1.round.startedAt {
                return $0.round.startedAt < $1.round.startedAt
            }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    public func delete(id: UUID) {
        records[id] = nil
        persist()
    }
}
