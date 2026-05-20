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
                        scorecard.yearbookCard()
                        stats.yearbookCard().frame(width: 320)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            stats.yearbookCard()
                            scorecard.yearbookCard()
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
        VStack(alignment: .leading, spacing: 14) {
            Text("本回合摘要")
                .font(.footnote.weight(.bold))
                .foregroundStyle(DS.fairway)
                .textCase(.uppercase)

            statRow("已打洞數", "\(s.holesPlayed)")
            statRow("相對標準桿",
                    s.totalToPar == 0 ? "E"
                    : (s.totalToPar > 0 ? "+\(s.totalToPar)" : "\(s.totalToPar)"),
                    accent: DS.scoreColor(diff: s.totalToPar))
            statRow("攻果嶺率 (GIR)", "\(s.greensInRegulation)/\(max(s.holesPlayed,1))")
            statRow("平均推桿", String(format: "%.2f", s.averagePuttsPerHole))
            statRow("一推 / 三推+", "\(s.onePutts) / \(s.threePuttsOrWorse)")

            Divider().padding(.vertical, 2)

            Text("成績分佈")
                .font(.footnote.weight(.bold))
                .foregroundStyle(DS.fairway)
                .textCase(.uppercase)
            distribution("Eagle+", s.eaglesOrBetter, DS.gold)
            distribution("Birdie",  s.birdies,         DS.fairway)
            distribution("Par",     s.pars,            .primary.opacity(0.65))
            distribution("Bogey",   s.bogeys,          DS.amber)
            distribution("Double",  s.doubleBogeys,    DS.bogey)
            distribution("Triple+", s.triplesOrWorse,  DS.bogey.opacity(0.6))
        }
        .accessibilityIdentifier("debrief.stats")
    }

    private func statRow(_ label: String, _ value: String,
                         accent: Color = .primary) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(accent)
        }
    }

    private func distribution(_ label: String, _ count: Int, _ color: Color) -> some View {
        HStack {
            Text(label)
                .frame(width: 70, alignment: .leading)
                .font(.caption.weight(.medium))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.15))
                    Capsule()
                        .fill(color)
                        .frame(width: max(4, geo.size.width * barFraction(count)))
                }
            }
            .frame(height: 12)
            Text("\(count)")
                .font(.caption.monospacedDigit())
                .frame(width: 24)
                .foregroundStyle(color)
        }
    }

    private func barFraction(_ count: Int) -> CGFloat {
        let maxCount = max(1, s.holesPlayed)
        return CGFloat(count) / CGFloat(maxCount)
    }

    private var scorecard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(vm.courseName)
                    .font(.headline)
                Spacer()
                Text("Par \(vm.coursePar)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Grid(horizontalSpacing: 12, verticalSpacing: 6) {
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
                            .foregroundStyle(DS.scoreColor(diff: c.gross == 0 ? 0 : c.gross - c.par))
                        Text(c.putts == 0 ? "–" : "\(c.putts)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .font(.subheadline.monospacedDigit())
        }
        .accessibilityIdentifier("debrief.scorecard")
    }
}

private extension Text {
    func gridColumnHeader() -> some View {
        self.font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}
