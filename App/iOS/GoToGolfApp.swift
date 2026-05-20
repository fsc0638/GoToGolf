import SwiftUI
import GolfCore

@main
struct GoToGolfApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(DS.fairway)
        }
    }
}

struct RootView: View {
    @State private var course: Course?

    var body: some View {
        if let course {
            RoundContainer(course: course) { self.course = nil }
        } else {
            CourseListView { self.course = $0 }
        }
    }
}

/// Hosts the round once a course is chosen. The scoring-only MVP shows
/// three tabs: 計分（scorecard grid）／複盤（stats）／差點（WHS+history+
/// subscription）. Map/distance tabs were removed with the GPS layer.
struct RoundContainer: View {
    @StateObject private var vm: RoundViewModel
    @State private var selectedTab: Tab = .scoring
    private let onExit: () -> Void

    enum Tab: Hashable { case scoring, debrief, history }

    init(course: Course, onExit: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: RoundViewModel(course: course, teeBox: .white))
        self.onExit = onExit
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ScoringView(vm: vm)
                .tabItem { Label("計分", systemImage: "list.number") }
                .tag(Tab.scoring)
            DebriefView(vm: vm)
                .tabItem { Label("複盤", systemImage: "square.grid.3x3.fill") }
                .tag(Tab.debrief)
            HistoryView(vm: vm)
                .tabItem { Label("差點", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tab.history)
        }
        .onChange(of: vm.roundSaved) { _, isSaved in
            // Auto-jump to the debrief tab the moment a round gets persisted,
            // so the OpenMoji summary card is what the user sees next.
            if isSaved { selectedTab = .debrief }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Button(action: onExit) {
                    Label("換球場", systemImage: "chevron.backward")
                        .labelStyle(.titleAndIcon)
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(DS.fairway)
                .accessibilityIdentifier("round.exitToCourses")
                Spacer()
                Text(vm.courseName)
                    .font(.footnote.weight(.semibold))
                    .accessibilityIdentifier("round.courseName")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }
}
