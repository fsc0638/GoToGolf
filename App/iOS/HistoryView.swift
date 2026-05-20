import SwiftUI
import Charts

/// Handicap tracking + round history — the premium-flavoured surface. End a
/// round here to run it through the WHS pipeline and persist it.
struct HistoryView: View {
    @ObservedObject var vm: RoundViewModel
    @StateObject private var subs = SubscriptionStore()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    handicapHero
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                Section("GoToGolf Premium") {
                    if subs.tier == .premium {
                        Label("已訂閱 · 差點追蹤已解鎖", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(DS.fairway)
                            .accessibilityIdentifier("upgrade.prompt")
                    } else {
                        upgradeCard
                    }
                    if let msg = subs.statusMessage {
                        Text(msg).font(.caption).foregroundStyle(.secondary)
                    }
                }

                Section("本回合") {
                    if vm.roundSaved {
                        HStack(spacing: 12) {
                            Image("openmoji-trophy")
                                .renderingMode(.original)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("已儲存本回合")
                                    .font(.headline)
                                    .foregroundStyle(DS.fairway)
                                Text("差點與歷史紀錄已更新")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .accessibilityIdentifier("history.finish")
                    } else {
                        Button {
                            vm.finishAndSave()
                        } label: {
                            Label("結束並儲存本回合", systemImage: "flag.checkered")
                        }
                        .accessibilityIdentifier("history.finish")
                    }
                }

                if !vm.history.isEmpty {
                    Section("近期表現") {
                        TrendChart(rows: vm.history)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16,
                                                      bottom: 8, trailing: 16))
                    }
                }

                Section("歷史球局") {
                    if vm.history.isEmpty {
                        Text("尚無紀錄").foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.history) { row in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(Self.dateFormatter.string(from: row.date))
                                        .font(.subheadline)
                                    Text("\(row.holes) 洞")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("總桿 \(row.gross)")
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(DS.fairway)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    vm.deleteRound(id: row.id)
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                                .accessibilityIdentifier("history.row.delete")
                            }
                        }
                    }
                }

                Section {
                    OpenMojiCredits()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("差點與歷史")
        }
    }

    private var handicapHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("世界差點 WHS")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white.opacity(0.85))
                .textCase(.uppercase)
            HStack(alignment: .lastTextBaseline) {
                Text(vm.handicapIndex.map { String(format: "%.1f", $0) } ?? "—")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("handicap.index")
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("已認證")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                    Text("\(vm.acceptedScores) 場")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.white)
                }
            }
            if vm.handicapIndex == nil {
                Text("打滿 3 場 (54 洞) 即可建立首個差點指數")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [DS.fairway, DS.fairway.opacity(0.78)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
    }

    private var upgradeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("升級 WHS 差點追蹤", systemImage: "star.circle.fill")
                .font(.headline)
                .foregroundStyle(DS.gold)
            Text(vm.showUpgradePrompt
                 ? "你已累積足夠成績,可建立人生首個正式差點指數並持續追蹤。"
                 : "解鎖 WHS 差點持續追蹤與平均差點分析。")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button {
                Task { await subs.purchase() }
            } label: {
                Text(subs.product.map { "升級（\($0.displayPrice) / 年）" } ?? "升級")
                    .frame(maxWidth: .infinity)
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(DS.fairway)
            .disabled(subs.product == nil || subs.purchasing)

            Button("還原購買") { Task { await subs.restore() } }
                .font(.footnote)
                .foregroundStyle(DS.fairway)
        }
        .accessibilityIdentifier("upgrade.prompt")
    }
}

/// Last-N rounds rendered as bars vs. par.
///
/// - Bars are coloured by DS.scoreColor(diff:) when course par is known,
///   so a glance shows whether the trend is creeping above par.
/// - Rounds whose course is no longer in the catalog fall back to a
///   neutral grey gross-only bar.
private struct TrendChart: View {
    let rows: [PastRoundRow]

    private struct Point: Identifiable {
        let id: UUID
        let index: Int
        let toPar: Int
        let gross: Int
        let hasCoursePar: Bool
    }

    private var points: [Point] {
        // rows arrive newest-first; reverse so the chart reads left → right
        // as oldest → newest. Cap to 20 rounds so the bar density stays sane.
        let chronological = Array(rows.reversed().suffix(20))
        return chronological.enumerated().map { idx, row in
            Point(id: row.id, index: idx + 1,
                  toPar: row.toPar ?? 0, gross: row.gross,
                  hasCoursePar: row.toPar != nil)
        }
    }

    private var allHavePar: Bool { points.allSatisfy(\.hasCoursePar) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(allHavePar ? "對標準桿趨勢" : "桿數趨勢")
                    .font(.footnote.weight(.semibold))
                Spacer()
                Text("最近 \(points.count) 場")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Chart(points) { p in
                BarMark(
                    x: .value("場次", p.index),
                    y: .value(allHavePar ? "對標準桿" : "桿數",
                              allHavePar ? p.toPar : p.gross)
                )
                .foregroundStyle(
                    allHavePar && p.hasCoursePar
                        ? DS.scoreColor(diff: p.toPar)
                        : Color.secondary
                )
                .cornerRadius(3)
                if allHavePar {
                    RuleMark(y: .value("Par", 0))
                        .foregroundStyle(.tertiary)
                        .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(.quaternary)
                    AxisValueLabel().font(.caption2)
                }
            }
            .frame(height: 110)
            .accessibilityIdentifier("history.trend")
        }
    }
}
