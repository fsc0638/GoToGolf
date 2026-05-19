import XCTest
@testable import GolfCore

/// End-to-end: fetched course + fetched weather flow into the same domain
/// engines the UI will call, with no glue code in between.
final class APIIntegrationTests: XCTestCase {

    func testParsedCourseDrivesDistanceAndWindStrategy() async throws {
        let layout = """
        {
          "courseId": "iG-77",
          "name": "Strategy Test GC",
          "ratings": { "white": { "courseRating": 70.0, "slopeRating": 120 } },
          "holes": [
            {
              "number": 1, "par": 4, "strokeIndex": 9,
              "tee":   { "lat": 25.0000, "lng": 121.0000 },
              "green": {
                "front":  { "lat": 25.0000, "lng": 121.0018 },
                "center": { "lat": 25.0000, "lng": 121.0020 },
                "back":   { "lat": 25.0000, "lng": 121.0022 }
              }
            }
          ]
        }
        """
        let igolf = IGolfClient(
            config: IGolfConfig(baseURL: URL(string: "https://x.test")!, apiKey: "K"),
            transport: StubTransport(json: layout)
        )
        let course = try await igolf.courseLayout(courseID: "iG-77")
        let hole = try XCTUnwrap(course.hole(1))

        // Distance tee -> green center, in yards (~200 yd, due East).
        let distance = hole.tee.distanceYards(to: hole.green.center)
        XCTAssertGreaterThan(distance, 150)
        XCTAssertLessThan(distance, 260)
        let bearing = hole.tee.bearingDegrees(to: hole.green.center)
        XCTAssertEqual(bearing, 90, accuracy: 1.0)   // shooting East

        // Weather: 8 m/s blowing FROM the East = pure headwind on this shot.
        let weatherJSON = """
        { "wind": { "speed": 8.0, "deg": 90 },
          "main": { "temp": 22, "humidity": 60, "pressure": 1012 } }
        """
        let weatherClient = WeatherClient(
            config: WeatherConfig(apiKey: "W"),
            transport: StubTransport(json: weatherJSON)
        )
        let weather = try await weatherClient.currentWeather(at: hole.tee)

        let effect = WindCompensationEngine().effect(
            weather: weather,
            shotBearingDegrees: bearing,
            nominalDistanceYards: distance
        )
        XCTAssertEqual(effect.relation, .headwind)
        XCTAssertLessThan(effect.distanceDeltaYards, 0)   // lands short
        XCTAssertGreaterThanOrEqual(effect.clubChange, 1) // take more club
        XCTAssertTrue(effect.advice.contains("逆風"))
    }
}
