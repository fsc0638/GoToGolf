import SwiftUI
import GolfCore

/// Course picker — the entry screen. Loads the chosen course's 圖資 from the
/// bundled catalog and hands a fully-parsed `Course` to the round.
struct CourseListView: View {
    let onSelect: (Course) -> Void

    private let entries = CourseCatalog.entries()

    var body: some View {
        NavigationStack {
            List {
                Section("選擇所在球場") {
                    ForEach(entries) { entry in
                        Button {
                            if let course = CourseCatalog.course(resource: entry.resource) {
                                onSelect(course)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.summary.name)
                                        .font(.headline)
                                    Text(entry.summary.id)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .accessibilityIdentifier("course.\(entry.summary.id)")
                    }
                }
            }
            .navigationTitle("GoToGolf")
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView("找不到球場圖資",
                                           systemImage: "mappin.slash")
                }
            }
        }
    }
}
