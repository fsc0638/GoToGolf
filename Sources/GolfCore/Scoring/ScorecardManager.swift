import Foundation

/// Holds the live round and exposes atomic, fully-undoable score edits.
/// Every mutation pushes an inverse onto the undo stack so a mis-tap is a
/// one-action fix (the full-screen scroll-wheel calls straight into this).
public final class ScorecardManager {
    public private(set) var round: Round
    private let course: Course

    private enum Op {
        case setGross(hole: Int, previous: Int)
        case setPutts(hole: Int, previous: Int)
        case setPenalties(hole: Int, previous: Int)
    }
    private var undoStack: [Op] = []

    public init(round: Round, course: Course) {
        self.round = round
        self.course = course
        // Seed an empty card so every hole exists.
        if round.scores.isEmpty {
            self.round.scores = course.holes.map {
                HoleScore(holeNumber: $0.id, gross: 0)
            }
        }
    }

    private func index(of hole: Int) -> Int? {
        round.scores.firstIndex { $0.holeNumber == hole }
    }

    public func score(for hole: Int) -> HoleScore? {
        index(of: hole).map { round.scores[$0] }
    }

    @discardableResult
    public func setGross(_ value: Int, hole: Int) -> Bool {
        guard let i = index(of: hole), value >= 0 else { return false }
        undoStack.append(.setGross(hole: hole, previous: round.scores[i].gross))
        round.scores[i].gross = value
        return true
    }

    @discardableResult
    public func increment(hole: Int) -> Bool {
        guard let current = score(for: hole) else { return false }
        return setGross(current.gross + 1, hole: hole)
    }

    @discardableResult
    public func decrement(hole: Int) -> Bool {
        guard let current = score(for: hole), current.gross > 0 else { return false }
        return setGross(current.gross - 1, hole: hole)
    }

    @discardableResult
    public func setPutts(_ value: Int, hole: Int) -> Bool {
        guard let i = index(of: hole), value >= 0 else { return false }
        undoStack.append(.setPutts(hole: hole, previous: round.scores[i].putts))
        round.scores[i].putts = value
        return true
    }

    @discardableResult
    public func setPenalties(_ value: Int, hole: Int) -> Bool {
        guard let i = index(of: hole), value >= 0 else { return false }
        undoStack.append(.setPenalties(hole: hole, previous: round.scores[i].penalties))
        round.scores[i].penalties = value
        return true
    }

    public var canUndo: Bool { !undoStack.isEmpty }

    @discardableResult
    public func undo() -> Bool {
        guard let op = undoStack.popLast() else { return false }
        switch op {
        case .setGross(let hole, let prev):
            if let i = index(of: hole) { round.scores[i].gross = prev }
        case .setPutts(let hole, let prev):
            if let i = index(of: hole) { round.scores[i].putts = prev }
        case .setPenalties(let hole, let prev):
            if let i = index(of: hole) { round.scores[i].penalties = prev }
        }
        return true
    }

    public var totalGross: Int { round.totalGross }

    public var totalToPar: Int {
        round.scores.reduce(0) { acc, s in
            guard s.gross > 0, let hole = course.hole(s.holeNumber) else { return acc }
            return acc + (s.gross - hole.par)
        }
    }

    /// Adjusted Gross Score for handicap submission.
    public func adjustedGrossScore(establishedCourseHandicap: Int?) -> Int {
        WHSEngine.adjustedGrossScore(
            round: round,
            course: course,
            establishedCourseHandicap: establishedCourseHandicap
        )
    }
}
