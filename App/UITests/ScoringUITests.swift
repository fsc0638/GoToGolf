import XCTest

/// Automates the scoring/navigation checklist. The app now opens on the
/// course picker, so every test first selects a bundled course to enter the
/// round. Geofence behaviour is driven by the GPX routes, not scripted here.
final class ScoringUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        selectCourse()
    }

    /// Tap a bundled course on the picker to enter the round.
    private func selectCourse() {
        let byID = app.descendants(matching: .any)
            .matching(identifier: "course.TW-PINEHILL").firstMatch
        if byID.waitForExistence(timeout: 8) {
            byID.tap()
            return
        }
        let byName = app.staticTexts["松丘高爾夫俱樂部"]
        XCTAssertTrue(byName.waitForExistence(timeout: 3), "找不到球場選單")
        byName.tap()
    }

    private func openTab(_ label: String) {
        let tab = app.tabBars.buttons[label]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "找不到『\(label)』分頁")
        tab.tap()
    }

    func testScoringTabShowsHoleAndScore() {
        openTab("計分")
        XCTAssertTrue(app.staticTexts["scoring.hole"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["scoring.gross"].exists)
    }

    /// The "1-second correction": a single vertical drag anywhere on the
    /// card must change the gross score.
    func testVerticalSlideIncreasesGross() {
        openTab("計分")
        let gross = app.staticTexts["scoring.gross"]
        XCTAssertTrue(gross.waitForExistence(timeout: 5))
        XCTAssertEqual(gross.label, "0", "新球局應從 0 桿開始")

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        let finish = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        start.press(forDuration: 0.1, thenDragTo: finish)   // swipe up = +score

        expectation(for: NSPredicate(format: "label != %@", "0"),
                    evaluatedWith: gross)
        waitForExpectations(timeout: 4)
        XCTAssertGreaterThan(Int(gross.label) ?? -1, 0, "上滑後總桿應增加")
    }

    func testCourseMapShowsDistance() {
        openTab("球道")
        XCTAssertTrue(app.staticTexts["map.distance"].waitForExistence(timeout: 5))
    }
}
