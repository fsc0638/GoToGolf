import Foundation

/// One pending score mutation awaiting delivery to the paired device.
public struct ScoreUpdate: Codable, Identifiable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case setGross, setPutts, undo
    }
    public let id: UUID
    public let holeNumber: Int
    public let kind: Kind
    public let value: Int
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        holeNumber: Int,
        kind: Kind,
        value: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.holeNumber = holeNumber
        self.kind = kind
        self.value = value
        self.createdAt = createdAt
    }
}

/// FIFO offline buffer mirroring the on-watch SQLite store.
///
/// When `sendMessage` can't reach the phone, the operation is enqueued and
/// flagged dirty. On reconnect `drain` replays items **in order**, stopping
/// at the first failure so nothing is delivered out of sequence — the
/// scorecard can never be corrupted by a mid-round Bluetooth drop.
public final class DirtyQueue<Item: Codable & Identifiable> where Item.ID: Hashable {
    private var items: [Item] = []
    private var indexByID: [Item.ID: Int] = [:]

    public init() {}

    public var pending: [Item] { items }
    public var count: Int { items.count }
    public var isEmpty: Bool { items.isEmpty }

    /// Enqueue, or replace an existing entry with the same id (idempotent —
    /// a retried op must not double-apply). Order is preserved on replace.
    public func enqueue(_ item: Item) {
        if let idx = indexByID[item.id] {
            items[idx] = item
        } else {
            items.append(item)
            indexByID[item.id] = items.count - 1
        }
    }

    /// Replay pending items oldest-first. `transmit` returns whether the
    /// item was delivered; the first `false` halts the drain and every
    /// remaining item (including the failed one) stays queued, in order.
    /// - Returns: number of items successfully delivered.
    @discardableResult
    public func drain(_ transmit: (Item) -> Bool) -> Int {
        var delivered = 0
        while let first = items.first {
            guard transmit(first) else { break }
            items.removeFirst()
            delivered += 1
        }
        rebuildIndex()
        return delivered
    }

    private func rebuildIndex() {
        indexByID.removeAll(keepingCapacity: true)
        for (i, item) in items.enumerated() { indexByID[item.id] = i }
    }

    // MARK: - Persistence (the SQLite blob equivalent)

    public func serialized() throws -> Data {
        try JSONEncoder().encode(items)
    }

    public func restore(from data: Data) throws {
        items = try JSONDecoder().decode([Item].self, from: data)
        rebuildIndex()
    }
}
