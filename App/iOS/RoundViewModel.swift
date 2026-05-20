import SwiftUI
import UIKit
import GolfCore

struct PastRoundRow: Identifiable {
    let id: UUID
    let date: Date
    let gross: Int
    let holes: Int
    /// Gross minus the par of the holes that were actually scored. `nil`
    /// when the original course is no longer in the catalog.
    let toPar: Int?
}

struct ScorecardCell: Identifiable {
    let id: Int          // hole number
    let par: Int
    let gross: Int
    let putts: Int
}

/// Thin binding layer for the scoring-only MVP. Owns the tested
/// `RoundSession`, mirrors per-hole scores for SwiftUI, persists finished
/// rounds via `FileRoundStore`, and derives the Handicap Index through the
/// tested WHS pipeline. No GPS / motion.
@MainActor
final class RoundViewModel: ObservableObject {
    @Published private(set) var currentHole = 1
    @Published private(set) var pendingSync = 0
    @Published private(set) var handicapIndex: Double?
    @Published private(set) var acceptedScores = 0
    @Published private(set) var roundSaved = false
    @Published private(set) var showUpgradePrompt = false
    @Published private(set) var history: [PastRoundRow] = []
    let courseName: String
    let coursePar: Int

    private let course: Course
    private let session: RoundSession
    private let watch = WatchConnectivityAdapter()
    private let store: FileRoundStore
    private let ledgerURL: URL
    private let deviceID: String
    private var contextRevision = 0

    var debrief: RoundStatistics {
        RoundAnalyzer.analyze(round: session.currentRound, course: course)
    }

    var scorecard: [ScorecardCell] {
        course.holes.map { hole in
            let s = session.currentRound.scores.first { $0.holeNumber == hole.id }
            return ScorecardCell(id: hole.id, par: hole.par,
                                 gross: s?.gross ?? 0, putts: s?.putts ?? 0)
        }
    }

    init(course: Course, teeBox: TeeBox) {
        self.course = course
        session = RoundSession(course: course, teeBox: teeBox)
        courseName = course.name
        coursePar = course.par
        store = FileRoundStore(fileURL: Self.docURL("rounds.json"))
        ledgerURL = Self.docURL("handicap.json")
        deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "ios-device"

        let ledger = HandicapLedger.read(from: ledgerURL)
        handicapIndex = ledger.index
        acceptedScores = ledger.acceptedCount
        history = Self.rows(from: store)
        refresh()
    }

    // MARK: - Scoring (per-hole, direct from the scorecard grid)

    func setGross(_ value: Int, hole: Int) {
        _ = session.setGross(max(0, value), hole: hole)
        refresh()
    }

    func setPutts(_ value: Int, hole: Int) {
        _ = session.setPutts(max(0, value), hole: hole)
        refresh()
    }

    func selectHole(_ hole: Int) {
        _ = session.selectHole(hole)
        refresh()
    }

    // MARK: - History mutations

    /// Remove a saved round and rebuild the handicap ledger from the
    /// remaining rounds so the displayed index stays consistent.
    func deleteRound(id: UUID) {
        store.delete(id: id)
        rebuildLedgerFromStore()
        history = Self.rows(from: store)
    }

    /// Re-submit every persisted round in chronological order so the
    /// HandicapLedger reflects only what's currently in the store.
    private func rebuildLedgerFromStore() {
        let catalog = CourseCatalog.entries()
        let chronological = store.all().sorted { $0.round.startedAt < $1.round.startedAt }
        var rebuilt = HandicapLedger(differentials: [])
        let service = HandicapService()
        for synced in chronological {
            guard let c = catalog.first(where: { $0.course.id == synced.round.courseID })?.course
            else { continue }
            if let result = try? service.submit(
                round: synced.round, course: c,
                priorDifferentials: rebuilt.differentials,
                currentHandicapIndex: rebuilt.index ?? 0) {
                rebuilt.record(result.differential)
            }
        }
        rebuilt.write(to: ledgerURL)
        handicapIndex = rebuilt.index
        acceptedScores = rebuilt.acceptedCount
    }

    // MARK: - Finish & persist

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
        pendingSync = session.pendingSyncCount

        // Push the authoritative hole to the watch (overwrite channel —
        // newest revision wins, kills the jump bug on reconnect).
        contextRevision += 1
        watch.pushContext(WatchContext(
            currentHole: currentHole, revision: contextRevision))
    }

    private static func docURL(_ name: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
    }

    private static func rows(from store: FileRoundStore) -> [PastRoundRow] {
        let catalog = CourseCatalog.entries()
        return store.all().reversed().map { synced in
            let course = catalog.first { $0.course.id == synced.round.courseID }?.course
            let toPar: Int? = course.map { c in
                let scoredHoleIDs = Set(synced.round.scores
                    .filter { $0.gross > 0 }
                    .map(\.holeNumber))
                let playedPar = c.holes
                    .filter { scoredHoleIDs.contains($0.id) }
                    .reduce(0) { $0 + $1.par }
                return synced.round.totalGross - playedPar
            }
            return PastRoundRow(id: synced.id,
                                date: synced.round.startedAt,
                                gross: synced.round.totalGross,
                                holes: synced.round.holesPlayed,
                                toPar: toPar)
        }
    }
}
