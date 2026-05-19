import Foundation

/// World Handicap System engine (WHS 2024 revision).
///
/// All formulas follow the product spec. The progressive table is the
/// product's documented variant, not blindly the USGA reference — see
/// `handicapIndex(from:)` for the exact mapping.
public enum WHSEngine {

    /// Slope rating of a standard-difficulty course.
    public static let standardSlope = 113.0

    // MARK: - Score Differential

    /// `(113 / Slope) x (AGS - CR - PCC)`, rounded to one decimal.
    public static func scoreDifferential(
        adjustedGrossScore: Int,
        courseRating: Double,
        slopeRating: Int,
        pcc: Double = 0
    ) -> Double {
        let raw = (standardSlope / Double(slopeRating))
            * (Double(adjustedGrossScore) - courseRating - pcc)
        return (raw * 10).rounded() / 10
    }

    // MARK: - Per-hole caps

    /// Net Double Bogey = Par + 2 + handicap strokes received on the hole.
    public static func netDoubleBogey(par: Int, strokesReceived: Int) -> Int {
        par + 2 + strokesReceived
    }

    /// Players without an established handicap cap every hole at Par + 5.
    public static func beginnerMaxScore(par: Int) -> Int {
        par + 5
    }

    /// Course Handicap = round(HI x Slope / 113 + (CR - Par)).
    public static func courseHandicap(
        handicapIndex: Double,
        slopeRating: Int,
        courseRating: Double,
        par: Int
    ) -> Int {
        let value = handicapIndex * Double(slopeRating) / standardSlope
            + (courseRating - Double(par))
        return Int(value.rounded())
    }

    /// Strokes a player receives on a hole given its stroke index.
    /// Course handicap is spread one stroke per hole by difficulty order,
    /// wrapping for handicaps above the hole count.
    public static func strokesReceived(
        courseHandicap: Int,
        strokeIndex: Int,
        holeCount: Int = 18
    ) -> Int {
        guard courseHandicap > 0, strokeIndex >= 1, strokeIndex <= holeCount else {
            return 0
        }
        let base = courseHandicap / holeCount
        let remainder = courseHandicap % holeCount
        return base + (strokeIndex <= remainder ? 1 : 0)
    }

    // MARK: - Adjusted Gross Score

    /// Applies the appropriate per-hole cap and sums the round.
    /// - For players with an established handicap, the cap is Net Double Bogey.
    /// - For beginners, the cap is Par + 5.
    public static func adjustedGrossScore(
        round: Round,
        course: Course,
        establishedCourseHandicap: Int?
    ) -> Int {
        var total = 0
        for score in round.scores where score.gross > 0 {
            guard let hole = course.hole(score.holeNumber) else {
                total += score.gross
                continue
            }
            let cap: Int
            if let ch = establishedCourseHandicap {
                let received = strokesReceived(
                    courseHandicap: ch,
                    strokeIndex: hole.strokeIndex,
                    holeCount: course.holes.count
                )
                cap = netDoubleBogey(par: hole.par, strokesReceived: received)
            } else {
                cap = beginnerMaxScore(par: hole.par)
            }
            total += min(score.gross, cap)
        }
        return total
    }
}
