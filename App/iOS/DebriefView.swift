import SwiftUI
import GolfCore

/// iPad cart console + post-round debrief. The wide layout is the
/// large-screen scorecard for the cart; the stats are the analytics layer
/// behind the "3D 戰術複盤" (computed by the tested `RoundAnalyzer`).
struct DebriefView: View {
    @ObservedObject var vm: RoundViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        NavigationStack {
            Group {
                if sizeClass == .regular {
                    HStack(alignment: .top, spacing: 24) {
                        scorecard
                        stats.frame(width: 320)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            stats
                            scorecard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("戰術複盤")
        }
    }

    private var s: RoundStatistics { vm.debrief }

    private var stats: some View {
        VStack(alignment: .leading, spacing: 12) {
            statRow("已打洞數", "\(s.holesPlayed)")
            statRow("相對標準桿",
                    s.totalToPar == 0 ? "E"
                    : (s.totalToPar > 0 ? "+\(s.totalToPar)" : "\(s.totalToPar)"))
            statRow("攻果嶺率 (GIR)", "\(s.greensInRegulation)/\(max(s.holesPlayed,1))")
            statRow("平均推桿", String(format: "%.2f", s.averagePuttsPerHole))
            statRow("一推 / 三推+", "\(s.onePutts) / \(s.threePuttsOrWorse)")

            Text("成績分佈").font(.headline).padding(.top, 4)
            distribution("Eagle+", s.eaglesOrBetter, .purple)
            distribution("Birdie", s.birdies, .red)
            distribution("Par", s.pars, .green)
            distribution("Bogey", s.bogeys, .orange)
            distribution("Double", s.doubleBogeys, .brown)
            distribution("Triple+", s.triplesOrWorse, .gray)
        }
        .accessibilityIdentifier("debrief.stats")
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.headline).monospacedDigit()
        }
    }

    private func distribution(_ label: String, _ count: Int, _ color: Color) -> some View {
        HStack {
            Text(label).frame(width: 70, alignment: .leading).font(.caption)
            GeometryReader { geo in
                Capsule()
                    .fill(color)
                    .frame(width: max(4, geo.size.width * barFraction(count)))
            }
            .frame(height: 14)
            Text("\(count)").font(.caption.monospacedDigit()).frame(width: 24)
        }
    }

    private func barFraction(_ count: Int) -> CGFloat {
        let maxCount = max(1, s.holesPlayed)
        return CGFloat(count) / CGFloat(maxCount)
    }

    private var scorecard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(vm.courseName) · 計分卡").font(.headline)
            Grid(horizontalSpacing: 10, verticalSpacing: 6) {
                GridRow {
                    Text("洞").gridColumnHeader()
                    Text("Par").gridColumnHeader()
                    Text("桿").gridColumnHeader()
                    Text("推").gridColumnHeader()
                }
                ForEach(vm.scorecard) { c in
                    GridRow {
                        Text("\(c.id)")
                        Text("\(c.par)").foregroundStyle(.secondary)
                        Text(c.gross == 0 ? "–" : "\(c.gross)")
                            .fontWeight(.semibold)
                            .foregroundStyle(scoreColor(c))
                        Text(c.putts == 0 ? "–" : "\(c.putts)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .font(.subheadline.monospacedDigit())
        }
        .accessibilityIdentifier("debrief.scorecard")
    }

    private func scoreColor(_ c: ScorecardCell) -> Color {
        guard c.gross > 0 else { return .primary }
        switch c.gross - c.par {
        case ..<0: return .red
        case 0:    return .green
        case 1:    return .orange
        default:   return .brown
        }
    }
}

private extension Text {
    func gridColumnHeader() -> some View {
        self.font(.caption.weight(.bold)).foregroundStyle(.secondary)
    }
}
