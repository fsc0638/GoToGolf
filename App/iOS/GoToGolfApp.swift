import SwiftUI
import GolfCore

@main
struct GoToGolfApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
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

/// Hosts the round once a course is chosen. A fresh `RoundViewModel` is
/// bound to the selected course's 圖資.
struct RoundContainer: View {
    @StateObject private var vm: RoundViewModel
    private let onExit: () -> Void

    init(course: Course, onExit: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: RoundViewModel(course: course, teeBox: .white))
        self.onExit = onExit
    }

    var body: some View {
        TabView {
            CourseMapView(vm: vm)
                .tabItem { Label("球道", systemImage: "map") }
            ScoringView(vm: vm)
                .tabItem { Label("計分", systemImage: "list.number") }
            DebriefView(vm: vm)
                .tabItem { Label("複盤", systemImage: "square.grid.3x3.fill") }
            HistoryView(vm: vm)
                .tabItem { Label("差點", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Button("← 換球場", action: onExit)
                    .font(.footnote)
                Spacer()
                Text(vm.courseName)
                    .font(.footnote.weight(.semibold))
                    .accessibilityIdentifier("round.courseName")
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(.bar)
        }
        .onAppear { vm.start() }
    }
}
