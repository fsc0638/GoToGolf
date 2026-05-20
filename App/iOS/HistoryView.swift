import SwiftUI

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
                    Button {
                        vm.finishAndSave()
                    } label: {
                        Label(vm.roundSaved ? "已儲存本回合" : "結束並儲存本回合",
                              systemImage: vm.roundSaved
                              ? "checkmark.circle.fill" : "flag.checkered")
                            .foregroundStyle(vm.roundSaved ? DS.fairway : .primary)
                    }
                    .disabled(vm.roundSaved)
                    .accessibilityIdentifier("history.finish")
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
                        }
                    }
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
