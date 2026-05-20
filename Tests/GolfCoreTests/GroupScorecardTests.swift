import XCTest
@testable import GolfCore

final class GroupScorecardTests: XCTestCase {

    private func course() -> Course {
        let holes = (1...9).map { Hole(id: $0, par: 4, strokeIndex: $0) }
        return Course(id: "C", name: "Nine", holes: holes,
                      ratings: [.white: TeeRating(courseRating: 35, slopeRating: 113)])
    }

    private func player(_ id: String, _ name: String, _ gross: [Int]) -> PlayerRound {
        let scores = gross.enumerated().map {
            HoleScore(holeNumber: $0.offset + 1, gross: $0.element)
        }
        return PlayerRound(
            id: id, name: name,
            round: Round(courseID: "C", teeBox: .white, scores: scores)
        )
    }

    // MARK: CoachInvite

    func testInviteValidityWindow() {
        let svc = InviteService(ttl: 3600)
        let now = Date(timeIntervalSince1970: 1000)
        let invite = svc.make(coachID: "coach-1", code: "ABC123", now: now)

        XCTAssertTrue(invite.isValid(now: now))
        XCTAssertTrue(invite.isValid(now: now.addingTimeInterval(3599)))
        XCTAssertFalse(invite.isValid(now: now.addingTimeInterval(3600)))   // expired
        XCTAssertFalse(invite.isValid(now: now.addingTimeInterval(-1)))     // before issue
        XCTAssertTrue(svc.redeem(invite, now: now.addingTimeInterval(1800)))
        XCTAssertFalse(svc.redeem(invite, now: now.addingTimeInterval(7200)))
    }

    // MARK: Leaderboard

    func testLeaderboardRanksByToParThenGrossThenName() {
        let board = GroupScorecard(course: course())
        let entries = board.leaderboard([
            player("a", "Alice", [4, 4, 4]),   // E, 12
            player("b", "Bob",   [3, 4, 4]),   // -1, 11
            player("c", "Cara",  [4, 4, 4]),   // E, 12  (tie with Alice -> name)
            player("d", "Dan",   [5, 5]),      // +2, 10, 2 holes
        ])
        XCTAssertEqual(entries.map(\.playerID), ["b", "a", "c", "d"])
        XCTAssertEqual(entries[0].toPar, -1)
        XCTAssertEqual(entries[1].name, "Alice")    // tie broken by name
        XCTAssertEqual(entries[3].holesPlayed, 2)
    }

    func testEmptyGroup() {
        XCTAssertTrue(GroupScorecard(course: course()).leaderboard([]).isEmpty)
    }
}
