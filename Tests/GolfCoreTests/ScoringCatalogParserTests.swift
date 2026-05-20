import XCTest
@testable import GolfCore

final class ScoringCatalogParserTests: XCTestCase {

    private let courseJSON = """
    {
      "id": "TW-DEMO",
      "name": "示範球場",
      "region": "桃園市",
      "holes": [
        { "number": 2, "par": 3, "strokeIndex": 15 },
        { "number": 1, "par": 4 }
      ],
      "ratings": {
        "white": { "courseRating": 70.0, "slopeRating": 122 }
      }
    }
    """

    func testCourseDecodesSortedAndAppliesDefaults() throws {
        let c = try ScoringCatalogParser.course(fromCourseJSON: Data(courseJSON.utf8))
        XCTAssertEqual(c.id, "TW-DEMO")
        XCTAssertEqual(c.name, "示範球場")
        XCTAssertEqual(c.holes.map(\.id), [1, 2])              // sorted
        XCTAssertEqual(c.par, 7)
        // Hole 1 had no strokeIndex — default = position in source array (1).
        XCTAssertEqual(c.hole(1)?.strokeIndex, 2)              // 2nd in JSON → idx 2
        XCTAssertEqual(c.hole(2)?.strokeIndex, 15)
        XCTAssertEqual(c.ratings[.white]?.courseRating, 70.0)
    }

    func testListingExposesRegion() throws {
        let l = try ScoringCatalogParser.listing(fromCourseJSON: Data(courseJSON.utf8))
        XCTAssertEqual(l.region, "桃園市")
        XCTAssertEqual(l.course.id, "TW-DEMO")
    }

    func testCatalogDecodesArray() throws {
        let array = "[\(courseJSON),\(courseJSON.replacingOccurrences(of: "TW-DEMO", with: "TW-D2"))]"
        let list = try ScoringCatalogParser.catalog(fromCatalogJSON: Data(array.utf8))
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list.map(\.id), ["TW-DEMO", "TW-D2"])
    }

    func testMalformedJSONMapsToDecodingError() {
        do {
            _ = try ScoringCatalogParser.course(fromCourseJSON: Data(#"{"id": 5}"#.utf8))
            XCTFail("expected failure")
        } catch let e as ScoringCatalogError {
            guard case .decoding = e else { return XCTFail("expected .decoding, got \(e)") }
        } catch { XCTFail("wrong error: \(error)") }
    }
}
