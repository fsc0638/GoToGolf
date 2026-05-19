import Foundation
import WatchConnectivity
import GolfCore

/// Bridges the real WCSession to GolfCore's pure sync model. The queue and
/// context-overwrite *semantics* live (and are tested) in GolfCore; this
/// only does transport.
final class WatchConnectivityAdapter: NSObject, WCSessionDelegate {
    private let queue = DirtyQueue<ScoreUpdate>()
    private let context = ApplicationContextChannel()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    /// Real-time stroke; on failure it falls back to the dirty queue so no
    /// stroke is ever lost across a Bluetooth drop.
    func send(_ update: ScoreUpdate) {
        guard WCSession.default.isReachable,
              let data = try? JSONEncoder().encode(
                SyncEnvelope(channel: .message, payload: update)) else {
            queue.enqueue(update)
            return
        }
        WCSession.default.sendMessage(["envelope": data], replyHandler: nil) { _ in
            self.queue.enqueue(update)
        }
    }

    /// Replay queued updates in order; stops at the first failure.
    func flush() {
        queue.drain { update in
            guard WCSession.default.isReachable,
                  let data = try? JSONEncoder().encode(
                    SyncEnvelope(channel: .message, payload: update)) else {
                return false
            }
            WCSession.default.sendMessage(["envelope": data], replyHandler: nil)
            return true
        }
    }

    /// Overwrite-style context (current hole / distance / wind).
    func pushContext(_ ctx: WatchContext) {
        context.push(ctx)
        if let data = try? JSONEncoder().encode(ctx) {
            try? WCSession.default.updateApplicationContext(["context": data])
        }
    }

    // MARK: WCSessionDelegate
    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {}

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif
}
