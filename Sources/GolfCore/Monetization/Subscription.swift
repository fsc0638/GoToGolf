import Foundation

public enum SubscriptionTier: String, Codable, Sendable {
    case free
    case premium
}

/// Free baseline = map, hazard avoidance, casual scoring (never gated).
/// Premium unlocks the long-term handicap/analysis surface.
public enum PremiumFeature: String, CaseIterable, Sendable {
    case handicapTracking   // WHS 差點持續追蹤
    case averageAnalysis    // 平均差點趨勢分析
    case debrief3D          // 3D 戰術複盤
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
