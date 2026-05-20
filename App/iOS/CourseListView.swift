import SwiftUI
import GolfCore

/// Course picker — the entry screen. Loads bundled Taiwan seed + any
/// user-created courses; "新增球場" opens the create flow.
struct CourseListView: View {
    let onSelect: (Course) -> Void

    @State private var entries: [CourseListing] = CourseCatalog.entries()
    @State private var showingCreate = false

    private var grouped: [(region: String, courses: [CourseListing])] {
        let by = Dictionary(grouping: entries, by: { $0.region ?? "其他" })
        return by.keys.sorted().map { ($0, by[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.region) { group in
                    Section(group.region) {
                        ForEach(group.courses) { entry in
                            Button {
                                onSelect(entry.course)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.course.name).font(.headline)
                                        Text("\(entry.course.holes.count) 洞 · Par \(entry.course.par)")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .accessibilityIdentifier("course.\(entry.course.id)")
                        }
                    }
                }
            }
            .navigationTitle("選擇所在球場")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Label("新增球場", systemImage: "plus")
                    }
                    .accessibilityIdentifier("course.add")
                }
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView("找不到球場",
                                           systemImage: "mappin.slash",
                                           description: Text("點右上「＋」新增你的球場"))
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateCourseView { listing in
                    entries = CourseCatalog.entries()
                    onSelect(listing.course)
                }
            }
        }
    }
}
