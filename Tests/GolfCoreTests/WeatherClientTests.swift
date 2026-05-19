import XCTest
@testable import GolfCore

final class WeatherClientTests: XCTestCase {

    private func client(_ stub: StubTransport) -> WeatherClient {
        WeatherClient(config: WeatherConfig(apiKey: "OWMKEY"), transport: stub)
    }

    func testCurrentWeatherNormalisesResponse() async throws {
        let json = """
        {
          "wind": { "speed": 6.0, "deg": 210, "gust": 9.2 },
          "main": { "temp": 24.3, "humidity": 65, "pressure": 1013 },
          "name": "Taipei"
        }
        """
        let stub = StubTransport(json: json)
        let snapshot = try await client(stub).currentWeather(
            at: GeoCoordinate(latitude: 25.03, longitude: 121.56)
        )

        XCTAssertEqual(snapshot.windSpeedMS, 6.0, accuracy: 1e-9)
        XCTAssertEqual(snapshot.windFromDegrees, 210, accuracy: 1e-9)
        XCTAssertEqual(snapshot.gustMS, 9.2)
        XCTAssertEqual(snapshot.temperatureC, 24.3, accuracy: 1e-9)
        XCTAssertEqual(snapshot.humidity, 65)
        XCTAssertEqual(snapshot.pressureHPa, 1013)
    }

    func testRequestCarriesQueryParameters() async throws {
        let json = """
        { "wind": { "speed": 1, "deg": 1 },
          "main": { "temp": 1, "humidity": 1, "pressure": 1 } }
        """
        let stub = StubTransport(json: json)
        _ = try await client(stub).currentWeather(
            at: GeoCoordinate(latitude: 25.0, longitude: 121.0)
        )

        let comps = URLComponents(
            url: try XCTUnwrap(stub.lastRequest?.url),
            resolvingAgainstBaseURL: false
        )
        let items = Dictionary(
            uniqueKeysWithValues: (comps?.queryItems ?? []).map { ($0.name, $0.value) }
        )
        XCTAssertEqual(items["lat"], "25.0")
        XCTAssertEqual(items["lon"], "121.0")
        XCTAssertEqual(items["units"], "metric")
        XCTAssertEqual(items["appid"], "OWMKEY")
        XCTAssertTrue(comps?.path.hasSuffix("/weather") ?? false)
    }

    func testGustIsOptional() async throws {
        let json = """
        { "wind": { "speed": 3.3, "deg": 90 },
          "main": { "temp": 20, "humidity": 50, "pressure": 1008 } }
        """
        let snapshot = try await client(StubTransport(json: json)).currentWeather(
            at: GeoCoordinate(latitude: 0, longitude: 0)
        )
        XCTAssertNil(snapshot.gustMS)
    }
}
