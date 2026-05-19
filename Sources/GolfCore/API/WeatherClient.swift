import Foundation

public struct WeatherConfig: Sendable {
    public let baseURL: URL
    public let apiKey: String

    public init(
        baseURL: URL = URL(string: "https://api.openweathermap.org/data/2.5")!,
        apiKey: String
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
}

/// OpenWeatherMap current-conditions client, normalised to `WeatherSnapshot`
/// so the strategy engine never sees raw API shapes or units.
public struct WeatherClient {
    private let config: WeatherConfig
    private let core: APIClientCore

    public init(config: WeatherConfig, transport: HTTPTransport = URLSessionTransport()) {
        self.config = config
        self.core = APIClientCore(transport: transport)
    }

    public func currentWeather(at coordinate: GeoCoordinate) async throws -> WeatherSnapshot {
        guard var components = URLComponents(
            url: config.baseURL.appendingPathComponent("weather"),
            resolvingAgainstBaseURL: false
        ) else {
            throw GolfAPIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lon", value: String(coordinate.longitude)),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "appid", value: config.apiKey)
        ]
        guard let url = components.url else { throw GolfAPIError.invalidURL }

        let dto: OWMResponseDTO = try await core.get(url)
        return dto.domain
    }
}
