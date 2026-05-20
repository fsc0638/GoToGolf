import Foundation

/// WatchConnectivity transport tiers — semantics are testable without WCSession.
///
/// - `message`: real-time, requires reachable. Failure path is the DirtyQueue.
/// - `applicationContext`: overwrite-only — only the newest state survives.
///   On reconnect both ends snap to it; this is what kills the jump bug.
/// - `userInfo`: background, guaranteed, FIFO (full scorecard / trend).
public enum SyncChannel: String, Codable, Sendable {
    case message
    case applicationContext
    case userInfo
}

public struct SyncEnvelope<Payload: Codable>: Codable {
    public let channel: SyncChannel
    public let payload: Payload

    public init(channel: SyncChannel, payload: Payload) {
        self.channel = channel
        self.payload = payload
    }
}

/// The compact, overwrite-style state the phone pushes to the watch. In the
/// scoring-only MVP this is just the current hole; richer fields can be
/// added back when geography returns.
public struct WatchContext: Codable, Equatable, Sendable {
    public var currentHole: Int
    /// Monotonic; a higher revision is strictly newer.
    public var revision: Int

    public init(currentHole: Int, revision: Int) {
        self.currentHole = currentHole
        self.revision = revision
    }
}

/// Models `updateApplicationContext`: only the newest payload is retained,
/// even if updates arrive out of order.
public final class ApplicationContextChannel {
    public private(set) var latest: WatchContext?

    public init() {}

    public func push(_ context: WatchContext) {
        guard let current = latest else { latest = context; return }
        if context.revision > current.revision { latest = context }
    }
}

public struct HoleStateSnapshot: Equatable, Sendable {
    public var hole: Int
    public var revision: Int
    public init(hole: Int, revision: Int) {
        self.hole = hole
        self.revision = revision
    }
}

/// On reconnect the watch reconciles its local hole against the authoritative
/// pushed context. A newer context moves the hole; a stale one can't.
public struct ContextReconciler {
    public init() {}

    public func reconcile(
        local: HoleStateSnapshot,
        incoming: WatchContext
    ) -> HoleStateSnapshot {
        guard incoming.revision > local.revision else { return local }
        return HoleStateSnapshot(hole: incoming.currentHole, revision: incoming.revision)
    }
}
