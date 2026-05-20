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
                    Section {
                        ForEach(group.courses) { entry in
                            CourseRow(entry: entry, onSelect: onSelect)
                                .listRowBackground(DS.cream.opacity(0.55))
                        }
                    } header: {
                        Text(group.region)
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(DS.fairway)
                            .textCase(.uppercase)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("選擇所在球場")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Label("新增球場", systemImage: "plus.circle.fill")
                            .foregroundStyle(DS.fairway)
                    }
                    .accessibilityIdentifier("course.add")
                }
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView("找不到球場",
                                           systemImage: "flag.circle",
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

private struct CourseRow: View {
    let entry: CourseListing
    let onSelect: (Course) -> Void

    var body: some View {
        Button {
            onSelect(entry.course)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "flag.fill")
                    .font(.body)
                    .foregroundStyle(DS.fairway)
                    .frame(width: 28, height: 28)
                    .background(DS.fairway.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.course.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    HoleParBadge(holes: entry.course.holes.count,
                                 par: entry.course.par)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("course.\(entry.course.id)")
    }
}

private struct HoleParBadge: View {
    let holes: Int
    let par: Int

    var body: some View {
        HStack(spacing: 8) {
            Text("\(holes) 洞")
            Text("·").foregroundStyle(.tertiary)
            Text("Par \(par)")
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
    }
}
