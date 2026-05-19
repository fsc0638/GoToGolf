import Foundation
import GolfCore

// A runnable smoke demo: composes the GolfCore modules into one simulated
// round and prints a report. No new domain logic — only public APIs.
// Run with:  swift run golfcore-demo

// MARK: - Build a sample 18-hole course

let pars = [4, 4, 3, 5, 4, 4, 3, 5, 4, 4, 4, 3, 5, 4, 4, 3, 5, 4]

let holes: [Hole] = pars.enumerated().map { idx, par in
    let n = idx + 1
    let tee = GeoCoordinate(latitude: 25.0 + Double(n) * 0.001, longitude: 121.0)
    let green = GreenPoints(
        front:  GeoCoordinate(latitude: tee.latitude, longitude: tee.longitude + 0.0013),
        center: GeoCoordinate(latitude: tee.latitude, longitude: tee.longitude + 0.0015),
        back:   GeoCoordinate(latitude: tee.latitude, longitude: tee.longitude + 0.0017)
    )
    return Hole(id: n, par: par, strokeIndex: n, tee: tee, green: green,
                hazards: [GeoCoordinate(latitude: tee.latitude, longitude: tee.longitude + 0.0008)])
}

let course = Course(
    id: "DEMO-1", name: "Sunrise Beginner Links",
    holes: holes,
    ratings: [
        .blue:  TeeRating(courseRating: 72.4, slopeRating: 132),
        .white: TeeRating(courseRating: 70.1, slopeRating: 124),
        .red:   TeeRating(courseRating: 68.0, slopeRating: 115)
    ]
)

// MARK: - Play the round through a RoundSession

let session = RoundSession(course: course, teeBox: .white)
let validGesture = SafeGesture(twoFingerLongPress: true, swipe: true)

// (gross, putts) the player will post per hole.
let card: [(Int, Int)] = [
    (4, 2), (5, 2), (3, 1), (6, 2), (4, 2), (4, 1), (2, 1), (7, 3), (5, 2),
    (4, 2), (5, 2), (3, 2), (6, 2), (4, 1), (4, 2), (4, 2), (6, 2), (5, 2)
]

// Hole 1: record strokes via real swing detection + GPS confirmation.
func swingStroke(at base: TimeInterval) {
    _ = session.ingest(motion: MotionSample(g: 1.0, timestamp: base))
    _ = session.ingest(motion: MotionSample(g: 5.0, timestamp: base + 0.1)) // peak
    _ = session.ingest(motion: MotionSample(g: 0.3, timestamp: base + 0.4)) // trough
    _ = session.confirmSwing(displacementMeters: 30, at: base + 3)          // ball moved
}
for i in 0..<card[0].0 { swingStroke(at: Double(i) * 20) }
session.recordPutts(card[0].1)

let teeDistance = session.greenDistances(
    playerAt: course.hole(1)!.tee
)?.centerYards ?? 0

// Holes 2...18: safe-gesture jump, then post the score.
for n in 2...18 {
    _ = session.manualJump(to: n, gesture: validGesture)
    session.recordGross(card[n - 1].0)
    session.recordPutts(card[n - 1].1)
}

let queuedBeforeSync = session.pendingSyncCount
let finished = session.finishRound()
let synced = session.drainSync { _ in true }   // simulate watch→phone flush

// MARK: - Handicap, statistics, power

let priorDifferentials = [16.2, 18.0, 14.5, 20.1, 17.3]
let handicap = try HandicapService().submit(
    round: finished,
    course: course,
    priorDifferentials: priorDifferentials,
    currentHandicapIndex: 17.0
)

let stats = RoundAnalyzer.analyze(round: finished, course: course)

let power = PowerBudgetEstimator()
let watchRemaining = power.remainingPercent(
    durationHours: 4.5, strategy: .bluetoothProxy,
    aodOptimized: true, preciseFraction: 0.15
)

let wind = WindCompensationEngine().effect(
    windSpeedMS: 8, windFromDegrees: 0,
    shotBearingDegrees: 0, nominalDistanceYards: 150
)

// MARK: - Report

func line(_ s: String = "") { print(s) }

line("==================================================")
line(" \(course.name)  ·  Par \(course.par)  ·  White tee")
line("==================================================")
line(" Hole 1 distance to green centre: \(Int(teeDistance.rounded())) yds")
line(" Hole 1 recorded via swing detection (4 confirmed swings)")
line()
line(" #   Par  Gross  Putts  +/-")
line(" ---  ---  -----  -----  ---")
for s in finished.scores.sorted(by: { $0.holeNumber < $1.holeNumber }) {
    let par = course.hole(s.holeNumber)?.par ?? 0
    let diff = s.gross - par
    let sign = diff == 0 ? "E" : (diff > 0 ? "+\(diff)" : "\(diff)")
    let row = String(format: " %2d   %2d    %2d     %2d    %@",
                     s.holeNumber, par, s.gross, s.putts, sign)
    line(row)
}
line(" ---  ---  -----  -----  ---")
line(String(format: " Tot       %3d    %3d    %@",
            finished.totalGross, finished.totalPutts,
            stats.totalToPar == 0 ? "E" : (stats.totalToPar > 0
                ? "+\(stats.totalToPar)" : "\(stats.totalToPar)")))
line()
line("--- WHS submission --------------------------------")
line(" Mode               : \(handicap.mode.rawValue)")
line(" Score differential : \(handicap.differential)")
line(" Accepted scores    : \(handicap.acceptedScoresCount)")
line(" New Handicap Index : "
     + (handicap.newHandicapIndex.map { "\($0)" } ?? "n/a (<3 scores)"))
line()
line("--- Round statistics ------------------------------")
line(" Holes played       : \(stats.holesPlayed)")
line(" Eagle+ / Birdie    : \(stats.eaglesOrBetter) / \(stats.birdies)")
line(" Par / Bogey        : \(stats.pars) / \(stats.bogeys)")
line(" Double / Triple+   : \(stats.doubleBogeys) / \(stats.triplesOrWorse)")
line(" Greens in reg.     : \(stats.greensInRegulation)/\(stats.holesPlayed)")
line(" 1-putts / 3-putts+ : \(stats.onePutts) / \(stats.threePuttsOrWorse)")
line(String(format: " Avg putts / hole   : %.2f", stats.averagePuttsPerHole))
line()
line("--- Sync & power ----------------------------------")
line(" Score updates queued: \(queuedBeforeSync)  →  flushed: \(synced)")
line(String(format: " Watch battery @4.5h : %.1f%% (proxy+AOD)  KPI>45%%: %@",
            watchRemaining,
            power.meetsPhase1KPI(strategy: .bluetoothProxy,
                                 aodOptimized: true, preciseFraction: 0.15)
            ? "PASS" : "FAIL"))
line(" Wind strategy       : \(wind.advice)")
line("==================================================")
