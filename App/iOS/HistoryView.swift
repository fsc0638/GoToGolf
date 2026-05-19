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
                Section("世界差點 (WHS)") {
                    HStack {
                        Text("差點指數")
                        Spacer()
                        Text(vm.handicapIndex.map { String(format: "%.1f", $0) }
                             ?? "尚未建立")
                            .font(.title3.weight(.bold))
                            .accessibilityIdentifier("handicap.index")
                    }
                    HStack {
                        Text("已認證成績")
                        Spacer()
                        Text("\(vm.acceptedScores) 場")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("GoToGolf Premium") {
                    if subs.tier == .premium {
                        Label("已訂閱 · 差點追蹤已解鎖", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .accessibilityIdentifier("upgrade.prompt")
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("升級 WHS 差點追蹤", systemImage: "star.circle.fill")
                                .font(.headline)
                            Text(vm.showUpgradePrompt
                                 ? "你已累積足夠成績，可建立人生首個正式差點指數並持續追蹤。"
                                 : "解鎖 WHS 差點持續追蹤與平均差點分析。")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Button {
                                Task { await subs.purchase() }
                            } label: {
                                Text(subs.product.map { "升級（\($0.displayPrice) / 年）" }
                                     ?? "升級")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(subs.product == nil || subs.purchasing)

                            Button("還原購買") { Task { await subs.restore() } }
                                .font(.footnote)
                        }
                        .accessibilityIdentifier("upgrade.prompt")
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
                                VStack(alignment: .leading) {
                                    Text(Self.dateFormatter.string(from: row.date))
                                        .font(.subheadline)
                                    Text("\(row.holes) 洞")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("總桿 \(row.gross)")
                                    .font(.headline)
                            }
                        }
                    }
                }
            }
            .navigationTitle("差點與歷史")
        }
    }
}
