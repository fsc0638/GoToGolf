import Foundation

public enum SubscriptionTier: String, Codable, Sendable {
    case free
    case premium
}

/// Free baseline = unlimited solo scoring, full per-round debrief, local
/// WHS handicap, swipe-delete history. Never gated.
///
/// Premium = the cross-device / shareable / portable layer:
///   - cloudSync      iCloud-mirrored rounds + WHS ledger across devices.
///   - exportRounds   CSV / PDF export of a round or full history.
///   - groupRound     One scorecard tracks up to 4 players in one tap.
public enum PremiumFeature: String, CaseIterable, Sendable {
    case cloudSync
    case exportRounds
    case groupRound
}

public struct EntitlementService: Sendable {
    public init() {}

    public func isAllowed(_ feature: PremiumFeature, tier: SubscriptionTier) -> Bool {
        tier == .premium
    }
}

/// Decides when to surface the (non-forced) upgrade prompt. Per the GTM
/// plan the nudge appears once the player has banked enough holes to be
/// ready for their first official WHS index (default 54 holes = 3 rounds).
public struct ConversionTrigger: Sendable {
    public let holeThreshold: Int

    public init(holeThreshold: Int = 54) {
        self.holeThreshold = holeThreshold
    }

    /// True only on the transition across the threshold, so the prompt is
    /// shown exactly once and never to existing subscribers.
    public func shouldPromptUpgrade(
        previousHolesPlayed: Int,
        totalHolesPlayed: Int,
        tier: SubscriptionTier
    ) -> Bool {
        tier == .free
            && previousHolesPlayed < holeThreshold
            && totalHolesPlayed >= holeThreshold
    }
}
