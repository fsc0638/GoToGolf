import Foundation

/// Maps to CoreLocation desired-accuracy constants without importing
/// CoreLocation, so the policy stays testable on any platform.
public enum LocationAccuracyTier: String, Equatable, Sendable {
    case coarse     // kCLLocationAccuracyHundredMeters
    case standard   // kCLLocationAccuracyNearestTenMeters
    case precise    // kCLLocationAccuracyBest

    /// Recommended GPS sample interval, seconds.
    public var sampleInterval: TimeInterval {
        switch self {
        case .coarse:   return 10
        case .standard: return 5
        case .precise:  return 1
        }
    }
}

/// Picks the accuracy tier from distance-to-green and motion state.
/// Precise GPS is the biggest battery drain, so it only switches on near
/// the green once the player has stopped walking (chip/putt setup).
public struct DynamicAccuracyController: Sendable {
    public let coarseAboveYards: Double
    public let preciseBelowYards: Double

    public init(coarseAboveYards: Double = 150, preciseBelowYards: Double = 50) {
        self.coarseAboveYards = coarseAboveYards
        self.preciseBelowYards = preciseBelowYards
    }

    public func tier(distanceToGreenYards: Double, isStationary: Bool) -> LocationAccuracyTier {
        if distanceToGreenYards > coarseAboveYards {
            return .coarse
        }
        if distanceToGreenYards <= preciseBelowYards && isStationary {
            return .precise
        }
        return .standard
    }
}
