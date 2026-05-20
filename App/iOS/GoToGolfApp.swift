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
    private let onExit: () -> Void

    init(course: Course, onExit: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: RoundViewModel(course: course, teeBox: .white))
        self.onExit = onExit
    }

    var body: some View {
        TabView {
            ScoringView(vm: vm)
                .tabItem { Label("計分", systemImage: "list.number") }
            DebriefView(vm: vm)
                .tabItem { Label("複盤", systemImage: "square.grid.3x3.fill") }
            HistoryView(vm: vm)
                .tabItem { Label("差點", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Button(action: onExit) {
                    Label("換球場", systemImage: "chevron.backward")
                        .labelStyle(.titleAndIcon)
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(DS.fairway)
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
