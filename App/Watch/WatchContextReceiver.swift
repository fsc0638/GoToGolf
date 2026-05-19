import Foundation
import WatchConnectivity
import GolfCore

/// Receives the phone's overwrite-style `WatchContext` and resolves the
/// authoritative hole via the tested `ContextReconciler` (a stale context
/// can never drag the hole backward — the anti-jump guarantee on the wrist).
@MainActor
final class WatchContextReceiver: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var hole = 1
    @Published private(set) var distanceToCenter = 0

    private let reconciler = ContextReconciler()
    private var snapshot = HoleStateSnapshot(hole: 1, revision: 0)

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {}

    nonisolated func session(_ session: WCSession,
                             didReceiveApplicationContext context: [String: Any]) {
        guard let data = context["context"] as? Data,
              let ctx = try? JSONDecoder().decode(WatchContext.self, from: data)
        else { return }
        Task { @MainActor in self.apply(ctx) }
    }

    private func apply(_ ctx: WatchContext) {
        let merged = reconciler.reconcile(local: snapshot, incoming: ctx)
        snapshot = merged
        hole = merged.hole
        if ctx.revision >= merged.revision {
            distanceToCenter = Int(ctx.greenCenterYards)
        }
    }
}
