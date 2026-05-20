import XCTest

/// Automates the scoring/navigation checklist for the scoring-only MVP.
/// The map tab and drag-to-score UI are gone; scoring is per-hole steppers.
final class ScoringUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        selectCourse()
    }

    /// Tap a bundled Taiwan course on the picker to enter the round.
    private func selectCourse() {
        let byID = app.descendants(matching: .any)
            .matching(identifier: "course.TW-TAMSUI").firstMatch
        if byID.waitForExistence(timeout: 8) {
            byID.tap()
            return
        }
        let byName = app.staticTexts["淡水高爾夫球場"]
        XCTAssertTrue(byName.waitForExistence(timeout: 3), "找不到球場選單")
        byName.tap()
    }

    private func openTab(_ label: String) {
        let tab = app.tabBars.buttons[label]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "找不到『\(label)』分頁")
        tab.tap()
    }

    func testScoringTabShowsScorecardGrid() {
        openTab("計分")
        XCTAssertTrue(app.staticTexts["scoring.hole.1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["scoring.gross.1"].exists)
        XCTAssertTrue(app.staticTexts["scoring.putts.1"].exists)
        // 18-hole bundled course → hole 18 row exists once we scroll the lazy List.
        let hole18 = app.staticTexts["scoring.hole.18"]
        var swipes = 0
        while !hole18.exists && swipes < 8 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(hole18.waitForExistence(timeout: 2))
    }

    /// Tapping the + button on hole 1's gross stepper must increase the value.
    func testTappingPlusIncrementsHoleGross() {
        openTab("計分")
        let gross = app.staticTexts["scoring.gross.1"]
        XCTAssertTrue(gross.waitForExistence(timeout: 5))
        XCTAssertEqual(gross.label, "–", "新球局未輸入桿數時應顯示破折號占位")

        let plus = app.buttons["scoring.gross.1.plus"]
        XCTAssertTrue(plus.waitForExistence(timeout: 2))
        plus.tap(); plus.tap(); plus.tap()

        expectation(for: NSPredicate(format: "label == %@", "3"),
                    evaluatedWith: gross)
        waitForExpectations(timeout: 3)
    }

    func testHistoryAndDebriefTabsLoad() {
        openTab("差點")
        XCTAssertTrue(app.staticTexts["handicap.index"].waitForExistence(timeout: 5))

        openTab("複盤")
        // DebriefView shows the scorecard grid; the stats container has id "debrief.stats".
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(identifier: "debrief.stats").firstMatch
                .waitForExistence(timeout: 5)
        )
    }
}
