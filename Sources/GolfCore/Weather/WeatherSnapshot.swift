import Foundation

/// Live conditions at the course, normalised to the units the strategy
/// engine expects (m/s, meteorological "from" degrees, Celsius).
public struct WeatherSnapshot: Equatable, Sendable {
    public let windSpeedMS: Double
    /// Direction the wind blows *from* (0 = N, 90 = E) — matches both
    /// OpenWeatherMap's `wind.deg` and `WindCompensationEngine`.
    public let windFromDegrees: Double
    public let gustMS: Double?
    public let temperatureC: Double
    public let humidity: Int
    public let pressureHPa: Int

    public init(
        windSpeedMS: Double,
        windFromDegrees: Double,
        gustMS: Double? = nil,
        temperatureC: Double,
        humidity: Int,
        pressureHPa: Int
    ) {
        self.windSpeedMS = windSpeedMS
        self.windFromDegrees = windFromDegrees
        self.gustMS = gustMS
        self.temperatureC = temperatureC
        self.humidity = humidity
        self.pressureHPa = pressureHPa
    }
}

extension WindCompensationEngine {
    /// Convenience: project a fetched weather snapshot onto a shot.
    public func effect(
        weather: WeatherSnapshot,
        shotBearingDegrees: Double,
        nominalDistanceYards: Double
    ) -> WindEffect {
        effect(
            windSpeedMS: weather.windSpeedMS,
            windFromDegrees: weather.windFromDegrees,
            shotBearingDegrees: shotBearingDegrees,
            nominalDistanceYards: nominalDistanceYards
        )
    }
}
