import XCTest
@testable import GolfCore

final class IGolfClientTests: XCTestCase {

    private func config() -> IGolfConfig {
        IGolfConfig(baseURL: URL(string: "https://api.igolf.test/v1")!, apiKey: "K")
    }

    private let layoutJSON = """
    {
      "courseId": "iG-900",
      "name": "Sunrise Links",
      "ratings": {
        "blue":  { "courseRating": 72.1, "slopeRating": 130 },
        "white": { "courseRating": 70.4, "slopeRating": 125 },
        "red":   { "courseRating": 68.2, "slopeRating": 118 }
      },
      "holes": [
        {
          "number": 2,
          "par": 3,
          "strokeIndex": 17,
          "tee": { "lat": 25.0700, "lng": 121.5500 },
          "green": {
            "front":  { "lat": 25.0710, "lng": 121.5500 },
            "center": { "lat": 25.0712, "lng": 121.5500 },
            "back":   { "lat": 25.0714, "lng": 121.5500 }
          },
          "hazards": [
            { "type": "water", "polygon": [
              { "lat": 25.0705, "lng": 121.5498 },
              { "lat": 25.0705, "lng": 121.5502 },
              { "lat": 25.0707, "lng": 121.5502 },
              { "lat": 25.0707, "lng": 121.5498 }
            ]}
          ]
        },
        {
          "number": 1,
          "par": 4,
          "strokeIndex": 5,
          "tee": { "lat": 25.0680, "lng": 121.5490 },
          "green": {
            "front":  { "lat": 25.0695, "lng": 121.5492 },
            "center": { "lat": 25.0697, "lng": 121.5492 },
            "back":   { "lat": 25.0699, "lng": 121.5492 }
          }
        }
      ]
    }
    """

    func testCourseLayoutMapsAndSortsHoles() async throws {
        let stub = StubTransport(json: layoutJSON)
        let client = IGolfClient(config: config(), transport: stub)

        let course = try await client.courseLayout(courseID: "iG-900")

        XCTAssertEqual(course.id, "iG-900")
        XCTAssertEqual(course.name, "Sunrise Links")
        XCTAssertEqual(course.holes.map(\.id), [1, 2])           // sorted
        XCTAssertEqual(course.par, 7)
        XCTAssertEqual(course.ratings[.blue]?.slopeRating, 130)
        XCTAssertEqual(course.ratings[.red]?.courseRating, 68.2)

        // Hazard polygon collapsed to its centroid.
        let hole2 = try XCTUnwrap(course.hole(2))
        XCTAssertEqual(hole2.hazards.count, 1)
        XCTAssertEqual(hole2.hazards[0].latitude, 25.0706, accuracy: 1e-6)
        XCTAssertEqual(hole2.hazards[0].longitude, 121.5500, accuracy: 1e-6)

        // No hazards on hole 1 -> empty, not nil.
        XCTAssertEqual(try XCTUnwrap(course.hole(1)).hazards.count, 0)

        // Auth + key both attached.
        XCTAssertEqual(
            stub.lastRequest?.value(forHTTPHeaderField: "Authorization"),
            "Bearer K"
        )
        XCTAssertEqual(stub.lastRequest?.url?.absoluteString,
                       "https://api.igolf.test/v1/courses/iG-900/layout?key=K")
    }

    func testSimpleGPSUsesPointHazards() async throws {
        let json = """
        {
          "courseId": "iG-1",
          "name": "Quick Nine",
          "ratings": { "white": { "courseRating": 35.2, "slopeRating": 120 } },
          "holes": [
            {
              "number": 1, "par": 4, "strokeIndex": 3,
              "tee": { "lat": 25.0, "lng": 121.0 },
              "green": {
                "front":  { "lat": 25.001, "lng": 121.0 },
                "center": { "lat": 25.002, "lng": 121.0 },
                "back":   { "lat": 25.003, "lng": 121.0 }
              },
              "hazards": [ { "lat": 25.0015, "lng": 121.0005 } ]
            }
          ]
        }
        """
        let stub = StubTransport(json: json)
        let client = IGolfClient(config: config(), transport: stub)

        let course = try await client.simpleGPS(courseID: "iG-1")
        let hole = try XCTUnwrap(course.hole(1))
        XCTAssertEqual(hole.hazards.count, 1)
        XCTAssertEqual(hole.hazards[0].latitude, 25.0015, accuracy: 1e-9)
        XCTAssertTrue(stub.lastRequest?.url?.absoluteString.hasSuffix(
            "/courses/iG-1/simple-gps?key=K") ?? false)
    }

    func testHTTPErrorIsMapped() async {
        let stub = StubTransport(status: 503)
        let client = IGolfClient(config: config(), transport: stub)
        do {
            _ = try await client.courseLayout(courseID: "x")
            XCTFail("expected failure")
        } catch let error as GolfAPIError {
            XCTAssertEqual(error, .httpStatus(503))
        } catch {
            XCTFail("wrong error type: \(error)")
        }
    }

    func testMalformedJSONIsMappedToDecodingError() async {
        let stub = StubTransport(json: #"{"courseId": 123}"#)
        let client = IGolfClient(config: config(), transport: stub)
        do {
            _ = try await client.courseLayout(courseID: "x")
            XCTFail("expected failure")
        } catch let error as GolfAPIError {
            guard case .decoding = error else {
                return XCTFail("expected .decoding, got \(error)")
            }
        } catch {
            XCTFail("wrong error type: \(error)")
        }
    }
}
