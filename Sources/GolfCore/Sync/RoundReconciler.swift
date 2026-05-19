import Foundation

/// Merges remote (CloudKit) rounds into the local store.
///
/// Policy: **Last-Write-Wins** by `updatedAt`, with **stroke protection**
/// overriding it — a gross score that was recorded on one device is never
/// erased by a staler device syncing a 0 for that hole. This is the
/// guarantee competitors fail (scorecards "corrupted on submit").
/// A completed round never reverts to in-progress either.
public struct RoundReconciler {
    public init() {}

    /// Merge one remote record against its local counterpart (if any).
    public func reconcile(local: SyncedRound?, remote: SyncedRound) -> SyncedRound {
        guard let local else { return remote }

        let localWins = local.updatedAt >= remote.updatedAt   // tie -> local
        let winner = localWins ? local : remote
        let loser = localWins ? remote : local

        let winnerScores = Dictionary(
            uniqueKeysWithValues: winner.round.scores.map { ($0.holeNumber, $0) }
        )
        let loserScores = Dictionary(
            uniqueKeysWithValues: loser.round.scores.map { ($0.holeNumber, $0) }
        )
        let holeNumbers = Set(winnerScores.keys).union(loserScores.keys).sorted()

        let mergedScores: [HoleScore] = holeNumbers.map { n in
            let w = winnerScores[n]
            let l = loserScores[n]
            // Stroke protection: a recorded score beats a missing/zero one,
            // regardless of who wrote last.
            let useLoser = (w?.gross ?? 0) == 0 && (l?.gross ?? 0) > 0
            let src = useLoser ? l : (w ?? l)
            return HoleScore(
                holeNumber: n,
                gross: src?.gross ?? 0,
                putts: src?.putts ?? 0,
                penalties: src?.penalties ?? 0
            )
        }

        let eitherCompleted =
            local.round.status == .completed || remote.round.status == .completed
        let mergedStatus: RoundStatus = eitherCompleted ? .completed : winner.round.status

        var mergedRound = winner.round
        mergedRound.scores = mergedScores
        mergedRound.status = mergedStatus
        mergedRound.finishedAt = winner.round.finishedAt ?? loser.round.finishedAt

        return SyncedRound(
            round: mergedRound,
            updatedAt: max(local.updatedAt, remote.updatedAt),
            deviceID: winner.deviceID
        )
    }

    /// Pull a batch of remote records into `store`, merging each. Local-only
    /// rounds are left untouched. Returns the post-merge snapshot.
    @discardableResult
    public func reconcile(
        store: RoundStore,
        incoming: [SyncedRound]
    ) -> [SyncedRound] {
        for remote in incoming {
            let merged = reconcile(local: store.round(id: remote.id), remote: remote)
            store.upsert(merged)
        }
        return store.all()
    }
}
