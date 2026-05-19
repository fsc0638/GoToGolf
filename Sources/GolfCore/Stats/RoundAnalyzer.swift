import Foundation

/// Post-round analytics — the data layer behind the Phase-4 debrief and the
/// core "help a beginner see their decision mistakes" value. Pure
/// computation over a finished round.
public struct RoundStatistics: Equatable, Sendable {
    public let holesPlayed: Int
    public let totalGross: Int
    public let totalToPar: Int
    public let totalPutts: Int

    // Scoring distribution (each bucket is per played hole, vs par).
    public let eaglesOrBetter: Int   // gross - par <= -2
    public let birdies: Int          // -1
    public let pars: Int             //  0
    public let bogeys: Int           // +1
    public let doubleBogeys: Int     // +2
    public let triplesOrWorse: Int   // >= +3

    /// Greens in regulation: reached the green with at least two strokes to
    /// spare for putting, i.e. (gross − putts) ≤ (par − 2).
    public let greensInRegulation: Int
    public let onePutts: Int
    public let threePuttsOrWorse: Int
    public let averagePuttsPerHole: Double
}

public enum RoundAnalyzer {

    public static func analyze(round: Round, course: Course) -> RoundStatistics {
        var holesPlayed = 0
        var totalGross = 0
        var totalToPar = 0
        var totalPutts = 0
        var eagles = 0, birdies = 0, pars = 0, bogeys = 0, doubles = 0, triples = 0
        var gir = 0, onePutts = 0, threePutts = 0

        for s in round.scores where s.gross > 0 {
            guard let hole = course.hole(s.holeNumber) else { continue }
            holesPlayed += 1
            totalGross += s.gross
            totalPutts += s.putts
            let diff = s.gross - hole.par
            totalToPar += diff

            switch diff {
            case ...(-2): eagles += 1
            case -1:      birdies += 1
            case 0:       pars += 1
            case 1:       bogeys += 1
            case 2:       doubles += 1
            default:      triples += 1
            }

            if (s.gross - s.putts) <= (hole.par - 2) { gir += 1 }
            if s.putts == 1 { onePutts += 1 }
            if s.putts >= 3 { threePutts += 1 }
        }

        let avgPutts = holesPlayed > 0
            ? Double(totalPutts) / Double(holesPlayed)
            : 0

        return RoundStatistics(
            holesPlayed: holesPlayed,
            totalGross: totalGross,
            totalToPar: totalToPar,
            totalPutts: totalPutts,
            eaglesOrBetter: eagles,
            birdies: birdies,
            pars: pars,
            bogeys: bogeys,
            doubleBogeys: doubles,
            triplesOrWorse: triples,
            greensInRegulation: gir,
            onePutts: onePutts,
            threePuttsOrWorse: threePutts,
            averagePuttsPerHole: avgPutts
        )
    }
}
