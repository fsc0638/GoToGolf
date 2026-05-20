import SwiftUI
import GolfCore

/// Scorecard grid: one row per hole with Par / Gross (+/−) / Putts (+/−).
/// Manual entry — no GPS/auto-detection.
struct ScoringView: View {
    @ObservedObject var vm: RoundViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 8) {
                        header("洞", width: 30)
                        header("Par", width: 40)
                        header("桿數", maxWidth: true)
                        header("推桿", maxWidth: true)
                    }
                    .listRowBackground(DS.cream)
                } header: {
                    HStack {
                        Text(vm.courseName)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("Par \(vm.coursePar)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    ForEach(vm.scorecard) { cell in
                        ScorecardRow(
                            cell: cell,
                            onGross: { vm.setGross($0, hole: cell.id) },
                            onPutts: { vm.setPutts($0, hole: cell.id) }
                        )
                        .listRowBackground(DS.cream.opacity(cell.gross > 0 ? 0.6 : 0.3))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .top, spacing: 0) {
                RunningSummaryBar(stats: vm.debrief, totalHoles: vm.scorecard.count)
            }
            .navigationTitle("計分卡")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if vm.pendingSync > 0 {
                        Label("\(vm.pendingSync)", systemImage: "arrow.triangle.2.circlepath")
                            .font(.footnote)
                            .foregroundStyle(DS.amber)
                    }
                }
            }
        }
    }

    private func header(_ text: String, width: CGFloat? = nil,
                        maxWidth: Bool = false) -> some View {
        let label = Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
        if let width {
            return AnyView(label.frame(width: width, alignment: .leading))
        }
        if maxWidth {
            return AnyView(label.frame(maxWidth: .infinity, alignment: .leading))
        }
        return AnyView(label)
    }
}

/// Sticky strip above the scorecard list showing live totals derived from
/// the same RoundStatistics the debrief screen uses.
private struct RunningSummaryBar: View {
    let stats: RoundStatistics
    let totalHoles: Int

    private var diffLabel: String {
        if stats.holesPlayed == 0 { return "—" }
        if stats.totalToPar == 0 { return "E" }
        return stats.totalToPar > 0 ? "+\(stats.totalToPar)" : "\(stats.totalToPar)"
    }

    private var diffColor: Color {
        stats.holesPlayed == 0 ? .secondary : DS.scoreColor(diff: stats.totalToPar)
    }

    var body: some View {
        HStack(spacing: 14) {
            stat("已打", "\(stats.holesPlayed)/\(totalHoles)",
                 identifier: "scoring.summary.played")
            Divider().frame(height: 26)
            stat("桿數", "\(stats.totalGross)",
                 identifier: "scoring.summary.gross")
            Divider().frame(height: 26)
            stat("相對", diffLabel, color: diffColor,
                 identifier: "scoring.summary.topar")
            Spacer()
            stat("推桿", "\(stats.totalPutts)",
                 identifier: "scoring.summary.putts")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(DS.cream)
        .overlay(alignment: .bottom) {
            Rectangle().fill(.separator).frame(height: 0.5)
        }
    }

    private func stat(_ label: String, _ value: String,
                      color: Color = .primary,
                      identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
                .accessibilityIdentifier(identifier)
        }
    }
}

private struct ScorecardRow: View {
    let cell: ScorecardCell
    let onGross: (Int) -> Void
    let onPutts: (Int) -> Void

    private var diff: Int { cell.gross > 0 ? cell.gross - cell.par : 0 }
    private var tag: String? { cell.gross > 0 ? DS.scoreTag(diff: diff) : nil }
    private var color: Color { DS.scoreColor(diff: diff) }

    var body: some View {
        HStack(spacing: 8) {
            // 洞號 + 桿差標籤
            VStack(alignment: .leading, spacing: 1) {
                Text("\(cell.id)")
                    .font(.headline.monospacedDigit())
                    .accessibilityIdentifier("scoring.hole.\(cell.id)")
                if let tag {
                    Text(tag)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(color)
                }
            }
            .frame(width: 30, alignment: .leading)

            Text("\(cell.par)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)

            stepper(value: cell.gross, range: 0...15,
                    onChange: onGross,
                    identifier: "scoring.gross.\(cell.id)",
                    valueColor: cell.gross > 0 ? color : .primary)

            stepper(value: cell.putts, range: 0...8,
                    onChange: onPutts,
                    identifier: "scoring.putts.\(cell.id)",
                    valueColor: .primary.opacity(0.85))
        }
        .padding(.vertical, 2)
    }

    private func stepper(value: Int, range: ClosedRange<Int>,
                         onChange: @escaping (Int) -> Void,
                         identifier: String,
                         valueColor: Color) -> some View {
        HStack(spacing: 6) {
            Button {
                if value > range.lowerBound { onChange(value - 1) }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(value <= range.lowerBound
                                     ? Color.secondary.opacity(0.35) : DS.fairway)
            }
            .buttonStyle(.borderless)
            .disabled(value <= range.lowerBound)
            .accessibilityIdentifier("\(identifier).minus")

            Text(value == 0 ? "–" : "\(value)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(value == 0 ? Color.secondary : valueColor)
                .frame(minWidth: 24, alignment: .center)
                .accessibilityIdentifier(identifier)

            Button {
                if value < range.upperBound { onChange(value + 1) }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(value >= range.upperBound
                                     ? Color.secondary.opacity(0.35) : DS.fairway)
            }
            .buttonStyle(.borderless)
            .disabled(value >= range.upperBound)
            .accessibilityIdentifier("\(identifier).plus")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
