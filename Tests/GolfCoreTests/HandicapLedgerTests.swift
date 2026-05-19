import XCTest
@testable import GolfCore

final class HandicapLedgerTests: XCTestCase {

    func testIndexDerivesFromWHS() {
        var l = HandicapLedger()
        XCTAssertNil(l.index)                 // < 3 scores
        l.record(14); l.record(10); l.record(12)
        XCTAssertEqual(l.acceptedCount, 3)
        // lowest 1 of [10,12,14] − 2.0 = 8.0  (matches WHSEngine)
        XCTAssertEqual(l.index, 8.0)
        XCTAssertEqual(l.index, WHSEngine.handicapIndex(from: l.differentials))
    }

    func testDiskRoundTrip() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ledger-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        var l = HandicapLedger()
        l.record(15.2); l.record(11.0)
        l.write(to: url)

        let loaded = HandicapLedger.read(from: url)
        XCTAssertEqual(loaded, l)
        XCTAssertEqual(loaded.differentials, [15.2, 11.0])
    }

    func testMissingFileYieldsEmptyLedger() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("missing-\(UUID().uuidString).json")
        XCTAssertEqual(HandicapLedger.read(from: url), HandicapLedger())
    }

    /// Submission pipeline → ledger → index, the App's persistence path.
    func testSubmissionThenLedgerIndex() throws {
        let g = GreenPoints(
            front: GeoCoordinate(latitude: 25, longitude: 121),
            center: GeoCoordinate(latitude: 25, longitude: 121),
            back: GeoCoordinate(latitude: 25, longitude: 121))
        let holes = (1...18).map {
            Hole(id: $0, par: 4, strokeIndex: $0,
                 tee: GeoCoordinate(latitude: 25, longitude: 121), green: g)
        }
        let course = Course(id: "C", name: "T", holes: holes,
                             ratings: [.white: TeeRating(courseRating: 72.0, slopeRating: 113)])
        let round = Round(courseID: "C", teeBox: .white,
                          scores: (1...18).map { HoleScore(holeNumber: $0, gross: 5) })

        var ledger = HandicapLedger()
        let result = try HandicapService().submit(
            round: round, course: course,
            priorDifferentials: ledger.differentials,
            currentHandicapIndex: ledger.index ?? 0)
        ledger.record(result.differential)

        XCTAssertEqual(result.differential, 18.0, accuracy: 1e-9)  // AGS 90
        XCTAssertEqual(ledger.differentials, [18.0])
    }
}
