import XCTest
@testable import GolfCore

final class MonetizationTests: XCTestCase {

    private let trigger = ConversionTrigger()   // threshold 54

    func testNoPromptBelowThreshold() {
        XCTAssertFalse(trigger.shouldPromptUpgrade(
            previousHolesPlayed: 0, totalHolesPlayed: 18, tier: .free))
    }

    func testPromptsExactlyOnCrossing() {
        XCTAssertTrue(trigger.shouldPromptUpgrade(
            previousHolesPlayed: 36, totalHolesPlayed: 54, tier: .free))
        XCTAssertTrue(trigger.shouldPromptUpgrade(
            previousHolesPlayed: 53, totalHolesPlayed: 55, tier: .free))
    }

    func testNoRepeatAfterCrossing() {
        XCTAssertFalse(trigger.shouldPromptUpgrade(
            previousHolesPlayed: 54, totalHolesPlayed: 72, tier: .free))
    }

    func testPremiumNeverPrompted() {
        XCTAssertFalse(trigger.shouldPromptUpgrade(
            previousHolesPlayed: 36, totalHolesPlayed: 54, tier: .premium))
    }

    func testEntitlementGating() {
        let e = EntitlementService()
        for f in PremiumFeature.allCases {
            XCTAssertTrue(e.isAllowed(f, tier: .premium))
            XCTAssertFalse(e.isAllowed(f, tier: .free))
        }
    }
}
