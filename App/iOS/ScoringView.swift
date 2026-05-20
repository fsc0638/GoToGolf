import SwiftUI

/// Scorecard grid: one row per hole with Par / Gross (+/−) / Putts (+/−).
/// Manual entry — no GPS/auto-detection.
struct ScoringView: View {
    @ObservedObject var vm: RoundViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("洞").frame(width: 32, alignment: .leading)
                        Text("Par").frame(width: 36, alignment: .leading)
                        Text("Gross").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Putts").frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                } header: {
                    Text(vm.courseName)
                }

                Section {
                    ForEach(vm.scorecard) { cell in
                        ScorecardRow(
                            cell: cell,
                            onGross: { vm.setGross($0, hole: cell.id) },
                            onPutts: { vm.setPutts($0, hole: cell.id) }
                        )
                    }
                }
            }
            .navigationTitle("計分卡")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if vm.pendingSync > 0 {
                        Label("\(vm.pendingSync)", systemImage: "arrow.triangle.2.circlepath")
                            .font(.footnote).foregroundStyle(.orange)
                    }
                }
            }
        }
    }
}

private struct ScorecardRow: View {
    let cell: ScorecardCell
    let onGross: (Int) -> Void
    let onPutts: (Int) -> Void

    var body: some View {
        HStack {
            Text("\(cell.id)")
                .frame(width: 32, alignment: .leading)
                .accessibilityIdentifier("scoring.hole.\(cell.id)")
            Text("\(cell.par)")
                .frame(width: 36, alignment: .leading)
                .foregroundStyle(.secondary)
            stepper(value: cell.gross, range: 0...15,
                    onChange: onGross,
                    identifier: "scoring.gross.\(cell.id)")
            stepper(value: cell.putts, range: 0...8,
                    onChange: onPutts,
                    identifier: "scoring.putts.\(cell.id)")
        }
        .font(.subheadline.monospacedDigit())
    }

    private func stepper(value: Int, range: ClosedRange<Int>,
                         onChange: @escaping (Int) -> Void,
                         identifier: String) -> some View {
        HStack(spacing: 4) {
            Button {
                if value > range.lowerBound { onChange(value - 1) }
            } label: { Image(systemName: "minus.circle") }
                .buttonStyle(.borderless)
                .disabled(value <= range.lowerBound)
                .accessibilityIdentifier("\(identifier).minus")

            Text("\(value)")
                .frame(minWidth: 22, alignment: .center)
                .accessibilityIdentifier(identifier)

            Button {
                if value < range.upperBound { onChange(value + 1) }
            } label: { Image(systemName: "plus.circle") }
                .buttonStyle(.borderless)
                .disabled(value >= range.upperBound)
                .accessibilityIdentifier("\(identifier).plus")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
