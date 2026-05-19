import Foundation

/// A round plus the sync metadata CloudKit needs. The app's Core Data /
/// CloudKit layer will conform a real store to `RoundStore`; this keeps the
/// merge logic testable without either framework.
public struct SyncedRound: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID { round.id }
    public var round: Round
    /// Wall-clock of the last local mutation — the Last-Write-Wins key.
    public var updatedAt: Date
    /// Origin device, for audit / tie-breaking diagnostics.
    public var deviceID: String

    public init(round: Round, updatedAt: Date, deviceID: String) {
        self.round = round
        self.updatedAt = updatedAt
        self.deviceID = deviceID
    }
}

public protocol RoundStore: AnyObject {
    func upsert(_ record: SyncedRound)
    func round(id: UUID) -> SyncedRound?
    func all() -> [SyncedRound]
    func delete(id: UUID)
}

/// Deterministic in-memory store for tests and previews.
public final class InMemoryRoundStore: RoundStore {
    private var records: [UUID: SyncedRound] = [:]

    public init() {}

    public func upsert(_ record: SyncedRound) {
        records[record.id] = record
    }

    public func round(id: UUID) -> SyncedRound? {
        records[id]
    }

    /// Stable ordering (by start time then id) so tests aren't flaky.
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
    }
}
