import Foundation

/// A WGS84 latitude/longitude point. Framework-agnostic so the domain logic
/// stays unit-testable without CoreLocation.
public struct GeoCoordinate: Codable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    private static let earthRadiusMeters = 6_372_797.560856
    public static let metersPerYard = 0.9144

    /// Great-circle (haversine) distance in meters.
    public func distanceMeters(to other: GeoCoordinate) -> Double {
        let lat1 = latitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let dLat = (other.latitude - latitude) * .pi / 180
        let dLon = (other.longitude - longitude) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return Self.earthRadiusMeters * c
    }

    /// Distance in golf yards (the unit shown on every screen).
    public func distanceYards(to other: GeoCoordinate) -> Double {
        distanceMeters(to: other) / Self.metersPerYard
    }

    /// Initial bearing in degrees (0 = North, 90 = East) toward `other`.
    public func bearingDegrees(to other: GeoCoordinate) -> Double {
        let lat1 = latitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let dLon = (other.longitude - longitude) * .pi / 180

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}
