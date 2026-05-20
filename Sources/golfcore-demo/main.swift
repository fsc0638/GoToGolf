import Foundation
import GolfCore

// A runnable smoke demo for the scoring-only MVP. No GPS / no motion —
// just a manual scorecard, persistence, the WHS submission pipeline, and
// post-round analytics. Run with:  swift run golfcore-demo

let holes = (1...18).map { Hole(id: $0, par: 4, strokeIndex: $0) }
let course = Course(
    id: "TW-DEMO", name: "示範球場",
    holes: holes,
    ratings: [
        .white: TeeRating(courseRating: 70.0, slopeRating: 122),
        .red:   TeeRating(courseRating: 68.0, slopeRating: 115)
    ]
)

let session = RoundSession(course: course, teeBox: .white)

// Manually entered scores for the 18 holes (gross, putts).
let card: [(Int, Int)] = [
    (4, 2), (5, 2), (4, 1), (6, 2), (4, 2), (4, 1), (3, 1), (7, 3), (5, 2),
    (4, 2), (5, 2), (4, 2), (6, 2), (4, 1), (4, 2), (4, 2), (6, 2), (5, 2)
]
for (idx, entry) in card.enumerated() {
    session.setGross(entry.0, hole: idx + 1)
    session.setPutts(entry.1, hole: idx + 1)
}

let queuedBefore = session.pendingSyncCount
let finished = session.finishRound()
let synced = session.drainSync { _ in true }    // simulate watch→phone flush

let priorDifferentials = [16.2, 18.0, 14.5, 20.1, 17.3]
let submission = try HandicapService().submit(
    round: finished, course: course,
    priorDifferentials: priorDifferentials,
    currentHandicapIndex: 17.0
)
let stats = RoundAnalyzer.analyze(round: finished, course: course)

print("==================================================")
print(" \(course.name)  ·  Par \(course.par)  ·  white tee")
print("==================================================")
print(" #   Par  Gross  Putts  +/-")
print(" ---  ---  -----  -----  ---")
for s in finished.scores.sorted(by: { $0.holeNumber < $1.holeNumber }) {
    let par = course.hole(s.holeNumber)?.par ?? 0
    let diff = s.gross - par
    let sign = diff == 0 ? "E" : (diff > 0 ? "+\(diff)" : "\(diff)")
    print(String(format: " %2d   %2d    %2d     %2d    %@",
                 s.holeNumber, par, s.gross, s.putts, sign))
}
print(" ---  ---  -----  -----  ---")
let totalSign = stats.totalToPar == 0 ? "E"
    : (stats.totalToPar > 0 ? "+\(stats.totalToPar)" : "\(stats.totalToPar)")
print(String(format: " Tot       %3d    %3d    %@",
             finished.totalGross, finished.totalPutts, totalSign))
print()
print("--- WHS submission --------------------------------")
print(" Mode               : \(submission.mode.rawValue)")
print(" Score differential : \(submission.differential)")
print(" Accepted scores    : \(submission.acceptedScoresCount)")
print(" New Handicap Index : "
      + (submission.newHandicapIndex.map { "\($0)" } ?? "n/a (<3 scores)"))
print()
print("--- Round statistics ------------------------------")
print(" Holes played       : \(stats.holesPlayed)")
print(" Eagle+ / Birdie    : \(stats.eaglesOrBetter) / \(stats.birdies)")
print(" Par / Bogey        : \(stats.pars) / \(stats.bogeys)")
print(" Double / Triple+   : \(stats.doubleBogeys) / \(stats.triplesOrWorse)")
print(" Greens in reg.     : \(stats.greensInRegulation)/\(stats.holesPlayed)")
print(" 1-putts / 3-putts+ : \(stats.onePutts) / \(stats.threePuttsOrWorse)")
print(String(format: " Avg putts / hole   : %.2f", stats.averagePuttsPerHole))
print()
print(" Score updates queued: \(queuedBefore)  →  flushed: \(synced)")
print("==================================================")
