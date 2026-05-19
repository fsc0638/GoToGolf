import Foundation

/// A coach-issued join code for the B2B2C "playing lesson" flow.
public struct CoachInvite: Codable, Equatable, Sendable {
    public let code: String
    public let coachID: String
    public let issuedAt: Date
    public let expiresAt: Date

    public init(code: String, coachID: String, issuedAt: Date, expiresAt: Date) {
        self.code = code
        self.coachID = coachID
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
    }

    public func isValid(now: Date) -> Bool {
        now >= issuedAt && now < expiresAt
    }
}

public struct InviteService: Sendable {
    public let ttl: TimeInterval

    public init(ttl: TimeInterval = 7 * 24 * 3600) {
        self.ttl = ttl
    }

    /// `code` is injected (StoreKit/registration layer supplies it) so the
    /// model stays deterministic and testable.
    public func make(coachID: String, code: String, now: Date) -> CoachInvite {
        CoachInvite(
            code: code, coachID: coachID,
            issuedAt: now, expiresAt: now.addingTimeInterval(ttl)
        )
    }

    public func redeem(_ invite: CoachInvite, now: Date) -> Bool {
        invite.isValid(now: now)
    }
}

public struct PlayerRound: Identifiable, Equatable, Sendable {
    public let id: String        // player id
    public let name: String
    public var round: Round

    public init(id: String, name: String, round: Round) {
        self.id = id
        self.name = name
        self.round = round
    }
}

public struct LeaderboardEntry: Equatable, Sendable {
    public let playerID: String
    public let name: String
    public let holesPlayed: Int
    public let toPar: Int
    public let gross: Int
}

/// Live group scorecard for the iPad cart console — recompute on every
/// update; ranks by to-par, then gross, then name for stable ordering.
public struct GroupScorecard {
    public let course: Course

    public init(course: Course) {
        self.course = course
    }

    private func toPar(_ round: Round) -> Int {
        round.scores.reduce(0) { acc, s in
            guard s.gross > 0, let hole = course.hole(s.holeNumber) else { return acc }
            return acc + (s.gross - hole.par)
        }
    }

    public func leaderboard(_ players: [PlayerRound]) -> [LeaderboardEntry] {
        players
            .map { p in
                LeaderboardEntry(
                    playerID: p.id,
                    name: p.name,
                    holesPlayed: p.round.holesPlayed,
                    toPar: toPar(p.round),
                    gross: p.round.totalGross
                )
            }
            .sorted {
                if $0.toPar != $1.toPar { return $0.toPar < $1.toPar }
                if $0.gross != $1.gross { return $0.gross < $1.gross }
                return $0.name < $1.name
            }
    }
}
