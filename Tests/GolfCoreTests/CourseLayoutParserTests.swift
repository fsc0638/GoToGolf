import XCTest
@testable import GolfCore

final class CourseLayoutParserTests: XCTestCase {

    private let layoutJSON = """
    {
      "courseId": "TW-PINEHILL",
      "name": "松丘高爾夫俱樂部",
      "ratings": {
        "blue":  { "courseRating": 71.8, "slopeRating": 129 },
        "white": { "courseRating": 70.0, "slopeRating": 122 }
      },
      "holes": [
        {
          "number": 2, "par": 3, "strokeIndex": 15,
          "tee": { "lat": 24.9001, "lng": 121.2001 },
          "green": {
            "front":  { "lat": 24.9010, "lng": 121.2001 },
            "center": { "lat": 24.9012, "lng": 121.2001 },
            "back":   { "lat": 24.9014, "lng": 121.2001 }
          },
          "hazards": [
            { "type": "bunker", "polygon": [
              { "lat": 24.9005, "lng": 121.2000 },
              { "lat": 24.9005, "lng": 121.2002 },
              { "lat": 24.9007, "lng": 121.2002 },
              { "lat": 24.9007, "lng": 121.2000 }
            ]}
          ]
        },
        {
          "number": 1, "par": 4, "strokeIndex": 7,
          "tee": { "lat": 24.9000, "lng": 121.2000 },
          "green": {
            "front":  { "lat": 24.9020, "lng": 121.2000 },
            "center": { "lat": 24.9022, "lng": 121.2000 },
            "back":   { "lat": 24.9024, "lng": 121.2000 }
          }
        }
      ]
    }
    """

    func testSummaryDecodesHeaderOnly() throws {
        let s = try CourseLayoutParser.summary(fromLayoutJSON: Data(layoutJSON.utf8))
        XCTAssertEqual(s.id, "TW-PINEHILL")
        XCTAssertEqual(s.name, "松丘高爾夫俱樂部")
    }

    func testCourseParsesAndSortsHoles() throws {
        let c = try CourseLayoutParser.course(fromLayoutJSON: Data(layoutJSON.utf8))
        XCTAssertEqual(c.id, "TW-PINEHILL")
        XCTAssertEqual(c.holes.map(\.id), [1, 2])      // sorted
        XCTAssertEqual(c.par, 7)
        XCTAssertEqual(c.ratings[.blue]?.slopeRating, 129)
        // Bunker polygon collapsed to a centroid pin.
        let h2 = try XCTUnwrap(c.hole(2))
        XCTAssertEqual(h2.hazards.count, 1)
        XCTAssertEqual(h2.hazards[0].latitude, 24.9006, accuracy: 1e-6)
    }

    func testParserMapsDecodeErrors() {
        do {
            _ = try CourseLayoutParser.course(fromLayoutJSON: Data(#"{"courseId":5}"#.utf8))
            XCTFail("expected failure")
        } catch let e as GolfAPIError {
            guard case .decoding = e else { return XCTFail("expected .decoding, got \(e)") }
        } catch { XCTFail("wrong error: \(error)") }
    }
}
