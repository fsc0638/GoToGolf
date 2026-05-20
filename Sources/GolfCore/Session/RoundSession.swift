import Foundation

/// The live-round application service for the manual-scoring MVP. Owns a
/// `ScorecardManager` and the sync queue; hole navigation is manual (no
/// geofence). GPS / motion / strategy were removed with the geo stack.
public final class RoundSession {
    public let course: Course
    public let syncQueue = DirtyQueue<ScoreUpdate>()

    private let card: ScorecardManager
    public private(set) var currentHole: Int

    public init(course: Course, teeBox: TeeBox, startedAt: Date = Date()) {
        self.course = course
        let round = Round(courseID: course.id, teeBox: teeBox, startedAt: startedAt)
        self.card = ScorecardManager(round: round, course: course)
        self.currentHole = course.holes.map(\.id).min() ?? 1
    }

    public var currentRound: Round { card.round }
    public var pendingSyncCount: Int { syncQueue.count }

    // MARK: - Scoring (per hole, direct addressing)

    @discardableResult
    public func setGross(_ value: Int, hole: Int) -> Bool {
        guard card.setGross(value, hole: hole),
              let s = card.score(for: hole) else { return false }
        syncQueue.enqueue(ScoreUpdate(holeNumber: hole, kind: .setGross, value: s.gross))
        return true
    }

    @discardableResult
    public func setPutts(_ value: Int, hole: Int) -> Bool {
        guard card.setPutts(value, hole: hole) else { return false }
        syncQueue.enqueue(ScoreUpdate(holeNumber: hole, kind: .setPutts, value: value))
        return true
    }

    @discardableResult
    public func undoLastEdit() -> Bool {
        let ok = card.undo()
        if ok, let s = card.score(for: currentHole) {
            syncQueue.enqueue(
                ScoreUpdate(holeNumber: currentHole, kind: .undo, value: s.gross)
            )
        }
        return ok
    }

    // MARK: - Hole navigation (manual; used for watch context)

    /// Set the currently-focused hole. Manual only — no GPS/geofence.
    @discardableResult
    public func selectHole(_ hole: Int) -> Bool {
        guard course.hole(hole) != nil else { return false }
        currentHole = hole
        return true
    }

    // MARK: - Lifecycle

    public func finishRound(now: Date = Date()) -> Round {
        var finished = card.round
        finished.finishedAt = now
        finished.status = .completed
        return finished
    }

    /// Drain queued score updates to the paired device.
    @discardableResult
    public func drainSync(_ transmit: (ScoreUpdate) -> Bool) -> Int {
        syncQueue.drain(transmit)
    }
}
