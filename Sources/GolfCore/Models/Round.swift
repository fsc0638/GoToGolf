import Foundation

public struct HoleScore: Codable, Hashable, Identifiable, Sendable {
    public var id: Int { holeNumber }
    public let holeNumber: Int
    public var gross: Int
    public var putts: Int
    public var penalties: Int

    public init(holeNumber: Int, gross: Int, putts: Int = 0, penalties: Int = 0) {
        self.holeNumber = holeNumber
        self.gross = gross
        self.putts = putts
        self.penalties = penalties
    }
}

public enum RoundStatus: String, Codable, Sendable {
    case inProgress, completed, abandoned
}

public struct Round: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let courseID: String
    public let teeBox: TeeBox
    public let startedAt: Date
    public var finishedAt: Date?
    public var scores: [HoleScore]
    /// Playing Conditions Calculation, -1.0...+3.0. Defaults to 0 until known.
    public var pcc: Double
    public var status: RoundStatus

    public init(
        id: UUID = UUID(),
        courseID: String,
        teeBox: TeeBox,
        startedAt: Date = Date(),
        finishedAt: Date? = nil,
        scores: [HoleScore] = [],
        pcc: Double = 0,
        status: RoundStatus = .inProgress
    ) {
        self.id = id
        self.courseID = courseID
        self.teeBox = teeBox
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.scores = scores
        self.pcc = pcc
        self.status = status
    }

    /// Holes that actually have a recorded gross score.
    public var holesPlayed: Int {
        scores.filter { $0.gross > 0 }.count
    }

    public var isNineHole: Bool {
        holesPlayed > 0 && holesPlayed <= 9
    }

    public var totalGross: Int {
        scores.reduce(0) { $0 + $1.gross }
    }

    public var totalPutts: Int {
        scores.reduce(0) { $0 + $1.putts }
    }
}
