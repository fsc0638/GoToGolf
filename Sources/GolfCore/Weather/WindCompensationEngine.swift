import Foundation

public enum WindRelation: String, Equatable, Sendable {
    case headwind   // costs distance
    case tailwind   // adds distance
    case crosswind  // mostly lateral
}

public struct WindEffect: Equatable, Sendable {
    /// Signed yards: negative = ball lands short, positive = lands long.
    public let distanceDeltaYards: Double
    public let relation: WindRelation
    /// Suggested club change: +1 = take one more club, -1 = one less.
    public let clubChange: Int
    /// Beginner-facing guidance, e.g. "強烈逆風，預估落點減少 15 碼，建議多一號鐵桿".
    public let advice: String
}

/// Projects wind onto the shot line and estimates the carry change so a
/// beginner can fold weather into club choice without having to feel it.
public struct WindCompensationEngine: Sendable {
    /// Yards lost per m/s of pure headwind on a 150-yard reference shot.
    public let headwindYardsPerMS: Double
    /// Yards gained per m/s of pure tailwind (asymmetric — wind hurts more
    /// than it helps).
    public let tailwindYardsPerMS: Double
    public let referenceDistanceYards: Double

    public init(
        headwindYardsPerMS: Double = 2.6,
        tailwindYardsPerMS: Double = 1.8,
        referenceDistanceYards: Double = 150
    ) {
        self.headwindYardsPerMS = headwindYardsPerMS
        self.tailwindYardsPerMS = tailwindYardsPerMS
        self.referenceDistanceYards = referenceDistanceYards
    }

    /// - Parameters:
    ///   - windSpeedMS: speed in m/s (OpenWeatherMap units=metric).
    ///   - windFromDegrees: meteorological direction the wind blows *from*
    ///     (0 = N, 90 = E).
    ///   - shotBearingDegrees: direction the ball travels (0 = N).
    ///   - nominalDistanceYards: the player's normal carry for this club.
    public func effect(
        windSpeedMS: Double,
        windFromDegrees: Double,
        shotBearingDegrees: Double,
        nominalDistanceYards: Double
    ) -> WindEffect {
        // Direction the wind blows toward.
        let windToDeg = (windFromDegrees + 180).truncatingRemainder(dividingBy: 360)
        let theta = (windToDeg - shotBearingDegrees) * .pi / 180

        let along = windSpeedMS * cos(theta)   // + = tailwind, - = headwind
        let cross = windSpeedMS * sin(theta)   // lateral component

        let scale = nominalDistanceYards / referenceDistanceYards
        let delta: Double
        if along >= 0 {
            delta = along * tailwindYardsPerMS * scale
        } else {
            delta = along * headwindYardsPerMS * scale   // negative
        }
        let roundedDelta = (delta * 10).rounded() / 10

        let relation: WindRelation
        if abs(cross) > abs(along) {
            relation = .crosswind
        } else {
            relation = along >= 0 ? .tailwind : .headwind
        }

        let magnitude = abs(roundedDelta)
        let clubChange: Int
        switch magnitude {
        case ..<8:    clubChange = 0
        case 8..<20:  clubChange = roundedDelta < 0 ? 1 : -1
        default:      clubChange = roundedDelta < 0 ? 2 : -2
        }

        let advice = Self.advice(
            relation: relation,
            delta: roundedDelta,
            clubChange: clubChange,
            crossYards: abs(cross) * scale
        )

        return WindEffect(
            distanceDeltaYards: roundedDelta,
            relation: relation,
            clubChange: clubChange,
            advice: advice
        )
    }

    private static func advice(
        relation: WindRelation,
        delta: Double,
        clubChange: Int,
        crossYards: Double
    ) -> String {
        let yards = Int(abs(delta).rounded())
        switch relation {
        case .headwind:
            let club = clubChange >= 2 ? "建議多兩號鐵桿"
                : clubChange == 1 ? "建議多一號鐵桿" : "可維持原球桿"
            return "逆風，預估落點減少 \(yards) 碼，\(club)"
        case .tailwind:
            let club = clubChange <= -2 ? "建議少兩號鐵桿"
                : clubChange == -1 ? "建議少一號鐵桿" : "可維持原球桿"
            return "順風，預估落點增加 \(yards) 碼，\(club)"
        case .crosswind:
            let side = Int(crossYards.rounded())
            return "側風，預估橫向偏移約 \(side) 碼，瞄準時請預留修正量"
        }
    }
}
