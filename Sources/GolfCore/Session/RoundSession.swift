import Foundation

/// The live-round application service. Owns and coordinates the geofence
/// lock, scorecard, swing detector and sync queue so the iOS/watchOS
/// ViewModels stay thin — they call this, they don't reimplement it.
public final class RoundSession {
    public let course: Course
    private let lock: GeofenceLock
    private let card: ScorecardManager
    private let swing: SwingDetector
    private let advisor = AimAdvisor()
    public let syncQueue = DirtyQueue<ScoreUpdate>()

    private var round: Round

    public init(
        course: Course,
        teeBox: TeeBox,
        startedAt: Date = Date(),
        swingDetector: SwingDetector = SwingDetector()
    ) {
        self.course = course
        self.round = Round(courseID: course.id, teeBox: teeBox, startedAt: startedAt)
        self.card = ScorecardManager(round: round, course: course)
        self.round = card.round
        let tees = Dictionary(
            uniqueKeysWithValues: course.holes.map { ($0.id, $0.tee) }
        )
        self.lock = GeofenceLock(currentHole: course.holes.map(\.id).min() ?? 1, tees: tees)
        self.swing = swingDetector
    }

    public var currentHole: Int { lock.currentHole }
    public var currentRound: Round { card.round }
    public var pendingSyncCount: Int { syncQueue.count }

    // MARK: - Strategy

    public func greenDistances(playerAt player: GeoCoordinate) -> GreenDistances? {
        guard let hole = course.hole(currentHole) else { return nil }
        return advisor.greenDistances(from: player, green: hole.green)
    }

    public func hazardCarries(
        playerAt player: GeoCoordinate,
        nominalShotYards: Double
    ) -> [HazardCarry] {
        guard let hole = course.hole(currentHole) else { return [] }
        return advisor.hazardCarries(
            from: player, hazards: hole.hazards, nominalShotYards: nominalShotYards
        )
    }

    // MARK: - Scoring

    private func enqueueGross() {
        guard let s = card.score(for: currentHole) else { return }
        syncQueue.enqueue(
            ScoreUpdate(holeNumber: currentHole, kind: .setGross, value: s.gross)
        )
    }

    /// Feed an accelerometer sample; returns a *tentative* swing if the
    /// peak→trough pattern just completed (still needs GPS confirmation).
    @discardableResult
    public func ingest(motion: MotionSample) -> SwingEvent? {
        swing.feed(motion)
    }

    /// Confirm with observed displacement. On a genuine stroke this records
    /// one shot on the current hole and queues it for sync.
    /// - Returns: true if a stroke was recorded.
    @discardableResult
    public func confirmSwing(displacementMeters: Double, at timestamp: TimeInterval) -> Bool {
        guard swing.confirm(displacementMeters: displacementMeters, at: timestamp) != nil else {
            return false
        }
        card.increment(hole: currentHole)
        enqueueGross()
        return true
    }

    public func recordGross(_ value: Int) {
        card.setGross(value, hole: currentHole)
        enqueueGross()
    }

    public func recordPutts(_ value: Int) {
        card.setPutts(value, hole: currentHole)
        syncQueue.enqueue(
            ScoreUpdate(holeNumber: currentHole, kind: .setPutts, value: value)
        )
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

    // MARK: - Hole navigation (anti-jump)

    @discardableResult
    public func updateLocation(_ coordinate: GeoCoordinate, now: TimeInterval) -> AdvanceResult {
        lock.update(coordinate: coordinate, now: now)
        return lock.tryAutoAdvance(now: now)
    }

    @discardableResult
    public func manualAdvance(gesture: SafeGesture) -> AdvanceResult {
        lock.manualAdvance(gesture: gesture)
    }

    @discardableResult
    public func manualJump(to hole: Int, gesture: SafeGesture) -> AdvanceResult {
        lock.manualJump(to: hole, gesture: gesture)
    }

    // MARK: - Lifecycle

    public func finishRound(now: Date = Date()) -> Round {
        var finished = card.round
        finished.finishedAt = now
        finished.status = .completed
        round = finished
        return finished
    }

    /// Drain queued score updates to the paired device. Returns count sent.
    @discardableResult
    public func drainSync(_ transmit: (ScoreUpdate) -> Bool) -> Int {
        syncQueue.drain(transmit)
    }
}
