import SwiftUI
import UIKit
import GolfCore

struct PastRoundRow: Identifiable {
    let id: UUID
    let date: Date
    let gross: Int
    let holes: Int
}

struct HoleMapSnapshot: Equatable {
    let tee: GeoCoordinate
    let greenCenter: GeoCoordinate
    let hazards: [GeoCoordinate]
    let player: GeoCoordinate?
}

struct ScorecardCell: Identifiable {
    let id: Int          // hole number
    let par: Int
    let gross: Int
    let putts: Int
}

/// Thin binding layer: owns the tested `RoundSession`, feeds it from the
/// framework adapters, persists finished rounds via `FileRoundStore`, and
/// derives the Handicap Index through the tested WHS pipeline.
@MainActor
final class RoundViewModel: ObservableObject {
    @Published private(set) var currentHole = 1
    @Published private(set) var distanceToCenter = 0
    @Published private(set) var gross = 0
    @Published private(set) var pendingSync = 0
    @Published private(set) var handicapIndex: Double?
    @Published private(set) var acceptedScores = 0
    @Published private(set) var roundSaved = false
    @Published private(set) var showUpgradePrompt = false
    @Published private(set) var history: [PastRoundRow] = []
    @Published private(set) var holeMap: HoleMapSnapshot?
    @Published private(set) var player: GeoCoordinate?
    let courseName: String

    /// Live post-round analytics for the debrief (tested in GolfCore).
    var debrief: RoundStatistics {
        RoundAnalyzer.analyze(round: session.currentRound, course: course)
    }

    /// Full hole-by-hole card for the iPad cart console.
    var scorecard: [ScorecardCell] {
        course.holes.map { hole in
            let s = session.currentRound.scores.first { $0.holeNumber == hole.id }
            return ScorecardCell(id: hole.id, par: hole.par,
                                 gross: s?.gross ?? 0, putts: s?.putts ?? 0)
        }
    }

    private let course: Course
    private let session: RoundSession
    private let location = CoreLocationAdapter()
    private let motion = MotionAdapter()
    private let accuracy = DynamicAccuracyController()
    private let watch = WatchConnectivityAdapter()
    private let store: FileRoundStore
    private let ledgerURL: URL
    private let deviceID: String
    private var lastCoord: GeoCoordinate?
    private var contextRevision = 0

    init(course: Course, teeBox: TeeBox) {
        self.course = course
        session = RoundSession(course: course, teeBox: teeBox)
        courseName = course.name
        store = FileRoundStore(fileURL: Self.docURL("rounds.json"))
        ledgerURL = Self.docURL("handicap.json")
        deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "ios-device"

        let ledger = HandicapLedger.read(from: ledgerURL)
        handicapIndex = ledger.index
        acceptedScores = ledger.acceptedCount
        history = Self.rows(from: store)
    }

    func start() {
        location.onUpdate = { [weak self] coord in self?.handle(coord) }
        motion.onSample = { [weak self] sample in _ = self?.session.ingest(motion: sample) }
        location.start()
        motion.start()
        refresh()
    }

    private func handle(_ coord: GeoCoordinate) {
        let now = Date().timeIntervalSince1970
        _ = session.updateLocation(coord, now: now)

        if let d = session.greenDistances(playerAt: coord) {
            distanceToCenter = Int(d.centerYards.rounded())
            location.apply(tier: accuracy.tier(
                distanceToGreenYards: d.centerYards, isStationary: false))
            if let prev = lastCoord {
                _ = session.confirmSwing(
                    displacementMeters: prev.distanceMeters(to: coord), at: now)
            }
        }
        lastCoord = coord
        player = coord
        refresh()
    }

    func adjustGross(_ value: Int) {
        session.recordGross(max(0, value))
        refresh()
    }

    func manualJump(to hole: Int) {
        _ = session.manualJump(
            to: hole, gesture: SafeGesture(twoFingerLongPress: true, swipe: true))
        refresh()
    }

    /// End the round: persist it, run the WHS submission pipeline, update
    /// the Handicap Index, and evaluate the upgrade trigger.
    func finishAndSave() {
        let priorHoles = store.all().reduce(0) { $0 + $1.round.holesPlayed }
        let round = session.finishRound()
        store.upsert(SyncedRound(round: round, updatedAt: Date(), deviceID: deviceID))

        var ledger = HandicapLedger.read(from: ledgerURL)
        if let result = try? HandicapService().submit(
            round: round, course: course,
            priorDifferentials: ledger.differentials,
            currentHandicapIndex: ledger.index ?? 0) {
            ledger.record(result.differential)
            ledger.write(to: ledgerURL)
        }
        handicapIndex = ledger.index
        acceptedScores = ledger.acceptedCount

        let totalHoles = priorHoles + round.holesPlayed
        showUpgradePrompt = ConversionTrigger().shouldPromptUpgrade(
            previousHolesPlayed: priorHoles,
            totalHolesPlayed: totalHoles,
            tier: .free)
        history = Self.rows(from: store)
        roundSaved = true
    }

    private func refresh() {
        currentHole = session.currentHole
        gross = session.currentRound.scores
            .first { $0.holeNumber == currentHole }?.gross ?? 0
        pendingSync = session.pendingSyncCount

        if let hole = course.hole(currentHole) {
            holeMap = HoleMapSnapshot(
                tee: hole.tee,
                greenCenter: hole.green.center,
                hazards: hole.hazards,
                player: player)
        }

        contextRevision += 1
        watch.pushContext(WatchContext(
            currentHole: currentHole,
            greenCenterYards: Double(distanceToCenter),
            windAdvice: nil,
            revision: contextRevision))
    }

    private static func docURL(_ name: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
    }

    private static func rows(from store: FileRoundStore) -> [PastRoundRow] {
        store.all().reversed().map {
            PastRoundRow(id: $0.id, date: $0.round.startedAt,
                         gross: $0.round.totalGross, holes: $0.round.holesPlayed)
        }
    }
}
