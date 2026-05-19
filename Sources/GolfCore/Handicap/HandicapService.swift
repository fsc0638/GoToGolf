import Foundation

public struct HandicapSubmission: Equatable, Sendable {
    /// The 18-hole-equivalent Score Differential produced by this round.
    public let differential: Double
    /// Recomputed Handicap Index, or nil if fewer than 3 acceptable scores.
    public let newHandicapIndex: Double?
    /// Total acceptable scores after this submission.
    public let acceptedScoresCount: Int
    /// How the round was scored into a differential.
    public let mode: Mode

    public enum Mode: String, Equatable, Sendable {
        case eighteen          // 18+ holes
        case nineHoleSameDay   // exactly 9...9 → Expected Score completes 18
        case unfinished        // 10...17 → Expected Score fills the rest
    }
}

public enum HandicapError: Error, Equatable {
    case noTeeRating
    case tooFewHoles   // < 9 holes is not an acceptable score
}

/// Turns a finished `Round` into a Score Differential and an updated
/// Handicap Index, applying the WHS 2024 paths (full 18, same-day 9-hole
/// Expected Score, and Expected-Score fill for 10–17 holes).
///
/// Simplification: the course only carries 18-hole ratings, so the 9-hole
/// path uses CourseRating/2 (slope unchanged) and the unfinished path
/// prorates CourseRating by holes played. Documented and self-consistent
/// with `WHSEngine`; swap in true 9-hole ratings when the data source has
/// them.
public struct HandicapService {
    public init() {}

    public func submit(
        round: Round,
        course: Course,
        priorDifferentials: [Double],
        currentHandicapIndex: Double
    ) throws -> HandicapSubmission {
        guard let rating = course.ratings[round.teeBox] else {
            throw HandicapError.noTeeRating
        }
        let holes = round.holesPlayed
        guard holes >= 9 else { throw HandicapError.tooFewHoles }

        let hasEstablished = WHSEngine.handicapIndex(from: priorDifferentials) != nil
        let courseHandicap: Int? = hasEstablished
            ? WHSEngine.courseHandicap(
                handicapIndex: currentHandicapIndex,
                slopeRating: rating.slopeRating,
                courseRating: rating.courseRating,
                par: course.par)
            : nil
        let ags = WHSEngine.adjustedGrossScore(
            round: round, course: course, establishedCourseHandicap: courseHandicap
        )

        let differential: Double
        let mode: HandicapSubmission.Mode

        switch holes {
        case 18...:
            differential = WHSEngine.scoreDifferential(
                adjustedGrossScore: ags,
                courseRating: rating.courseRating,
                slopeRating: rating.slopeRating,
                pcc: round.pcc
            )
            mode = .eighteen

        case 9:
            let nine = WHSEngine.scoreDifferential(
                adjustedGrossScore: ags,
                courseRating: rating.courseRating / 2,
                slopeRating: rating.slopeRating,
                pcc: round.pcc
            )
            differential = WHSEngine.eighteenHoleDifferential(
                fromNineHole: nine, currentHandicapIndex: currentHandicapIndex
            )
            mode = .nineHoleSameDay

        default: // 10...17
            let proratedCR = rating.courseRating * Double(holes) / 18
            let portion = WHSEngine.scoreDifferential(
                adjustedGrossScore: ags,
                courseRating: proratedCR,
                slopeRating: rating.slopeRating,
                pcc: round.pcc
            )
            guard let filled = WHSEngine.differentialForUnfinishedRound(
                holesPlayed: holes,
                playedDifferentialPortion: portion,
                currentHandicapIndex: currentHandicapIndex
            ) else {
                throw HandicapError.tooFewHoles
            }
            differential = filled
            mode = .unfinished
        }

        let history = priorDifferentials + [differential]
        return HandicapSubmission(
            differential: differential,
            newHandicapIndex: WHSEngine.handicapIndex(from: history),
            acceptedScoresCount: history.count,
            mode: mode
        )
    }
}
