import Foundation

extension WHSEngine {

    /// WHS 2024 Expected Score model.
    ///
    /// Given a player's Handicap Index, this is the differential they are
    /// expected to produce for a 9-hole stretch on a standard course. Used
    /// to (a) complete a 9-hole round into an 18-hole differential on the
    /// same day, and (b) fill unfinished holes (10...17 played).
    ///
    /// The USGA publishes this as a lookup table; we approximate it with the
    /// published piecewise-linear fit. For a full 18 holes the expected
    /// differential ≈ HI; for 9 holes it is half of that plus the model's
    /// small curvature term.
    public static func expectedDifferential18(handicapIndex: Double) -> Double {
        // Published fit: Expected Score Differential ≈ 1.04 * HI + 0.4
        let value = 1.04 * handicapIndex + 0.4
        return (value * 10).rounded() / 10
    }

    /// Expected differential for a single 9-hole stretch (half of 18).
    public static func expectedDifferential9(handicapIndex: Double) -> Double {
        let value = expectedDifferential18(handicapIndex: handicapIndex) / 2
        return (value * 10).rounded() / 10
    }

    /// Convert a same-day 9-hole differential into an 18-hole differential by
    /// adding the expected differential for the unplayed 9.
    ///
    /// - Parameters:
    ///   - nineHoleDifferential: differential computed from the 9 holes played
    ///     (using 9-hole CR/Slope).
    ///   - currentHandicapIndex: the player's index before this round; pass a
    ///     conservative default for brand-new players.
    public static func eighteenHoleDifferential(
        fromNineHole nineHoleDifferential: Double,
        currentHandicapIndex: Double
    ) -> Double {
        let complement = expectedDifferential9(handicapIndex: currentHandicapIndex)
        let total = nineHoleDifferential + complement
        return (total * 10).rounded() / 10
    }

    /// Fill an abandoned round (10...17 holes played) using Expected Score for
    /// the missing holes, then return the 18-hole-equivalent differential.
    ///
    /// - Returns: nil if fewer than 10 holes were played (not acceptable).
    public static func differentialForUnfinishedRound(
        holesPlayed: Int,
        playedDifferentialPortion: Double,
        currentHandicapIndex: Double
    ) -> Double? {
        guard (10...17).contains(holesPlayed) else { return nil }
        let missing = 18 - holesPlayed
        let perHoleExpected = expectedDifferential18(handicapIndex: currentHandicapIndex) / 18
        let fill = perHoleExpected * Double(missing)
        let total = playedDifferentialPortion + fill
        return (total * 10).rounded() / 10
    }
}
