import Foundation

/// Front / center / back yardages — the three-colour concentric rings the
/// beginner sees on the map and watch.
public struct GreenDistances: Equatable, Sendable {
    public let frontYards: Double
    public let centerYards: Double
    public let backYards: Double
}

public struct HazardCarry: Equatable, Sendable {
    /// Straight-line yards from the player to the hazard marker.
    public let carryYards: Double
    /// Whether the player's normal carry for the chosen club clears it.
    public let cleared: Bool
}

/// Pure geometry for on-course strategy. No framework dependencies.
public struct AimAdvisor: Sendable {
    public init() {}

    public func greenDistances(
        from player: GeoCoordinate,
        green: GreenPoints
    ) -> GreenDistances {
        GreenDistances(
            frontYards: player.distanceYards(to: green.front),
            centerYards: player.distanceYards(to: green.center),
            backYards: player.distanceYards(to: green.back)
        )
    }

    /// Carry distance to each hazard and whether the chosen club clears it,
    /// nearest hazard first — drives the avoidance prompts.
    public func hazardCarries(
        from player: GeoCoordinate,
        hazards: [GeoCoordinate],
        nominalShotYards: Double
    ) -> [HazardCarry] {
        hazards
            .map { hazard in
                let carry = player.distanceYards(to: hazard)
                return HazardCarry(carryYards: carry, cleared: nominalShotYards >= carry)
            }
            .sorted { $0.carryYards < $1.carryYards }
    }

    /// Layup target: the longest club whose carry stays short of the nearest
    /// *unclearable* hazard, leaving a margin. Returns nil if nothing to lay
    /// up for (every hazard is clearable or none in range).
    public func suggestedLayupYards(
        from player: GeoCoordinate,
        hazards: [GeoCoordinate],
        clubCarriesYards: [Double],
        safetyMarginYards: Double = 10
    ) -> Double? {
        let carries = hazardCarries(
            from: player, hazards: hazards, nominalShotYards: .greatestFiniteMagnitude
        )
        guard let nearestHazard = carries.first?.carryYards else { return nil }
        let ceiling = nearestHazard - safetyMarginYards
        let safeClubs = clubCarriesYards.filter { $0 <= ceiling }.sorted()
        return safeClubs.last
    }
}
