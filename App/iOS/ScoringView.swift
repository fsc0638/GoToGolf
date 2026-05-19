import SwiftUI

/// Full-screen card: single-finger vertical drag anywhere adjusts the
/// score (the "1-second correction" requirement). 44 pt per stroke.
struct ScoringView: View {
    @ObservedObject var vm: RoundViewModel
    @State private var dragBase = 0

    var body: some View {
        VStack(spacing: 14) {
            Text("第 \(vm.currentHole) 洞")
                .font(.headline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("scoring.hole")

            Text("\(vm.gross)")
                .font(.system(size: 150, weight: .black, design: .rounded))
                .monospacedDigit()
                .accessibilityIdentifier("scoring.gross")

            Text("總桿 · 上下滑動微調")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if vm.pendingSync > 0 {
                Label("\(vm.pendingSync) 筆待同步", systemImage: "arrow.triangle.2.circlepath")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    let delta = Int((-value.translation.height / 44).rounded())
                    vm.adjustGross(dragBase + delta)
                }
                .onEnded { _ in dragBase = vm.gross }
        )
        .onAppear { dragBase = vm.gross }
        .onChange(of: vm.currentHole) { _, _ in dragBase = vm.gross }
    }
}
