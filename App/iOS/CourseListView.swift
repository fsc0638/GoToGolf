import SwiftUI
import GolfCore

/// Course picker — the entry screen. Loads bundled Taiwan seed + any
/// user-created courses; "新增球場" opens the create flow.
struct CourseListView: View {
    let onSelect: (Course) -> Void

    @State private var entries: [CourseListing] = CourseCatalog.entries()
    @State private var showingCreate = false
    @State private var editingPar: CourseListing?
    @State private var pendingEntry: CourseListing?

    /// Route a course tap: if pars are already confirmed, enter the round
    /// directly; otherwise pop the par editor so the player corrects the
    /// template against the real scorecard before the first round.
    private func handleTap(_ entry: CourseListing) {
        if CourseCatalog.isParConfirmed(courseID: entry.course.id) {
            onSelect(entry.course)
        } else {
            pendingEntry = entry
        }
    }

    /// Trailing swipe actions for a course row. Extracted as a method
    /// because inlining the buttons made the body fail to type-check.
    @ViewBuilder
    private func rowSwipeActions(for entry: CourseListing) -> some View {
        if CourseCatalog.isUserAdded(entry.course.id) {
            Button(role: .destructive) {
                CourseCatalog.deleteUserCourse(id: entry.course.id)
                entries = CourseCatalog.entries()
            } label: {
                Label("刪除", systemImage: "trash")
            }
            .accessibilityIdentifier("course.delete.\(entry.course.id)")
        }
        Button {
            editingPar = entry
        } label: {
            Label("編輯 Par", systemImage: "pencil")
        }
        .tint(DS.fairway)
        .accessibilityIdentifier("course.editpar.\(entry.course.id)")
    }

    private var grouped: [(region: String, courses: [CourseListing])] {
        let by = Dictionary(grouping: entries, by: { $0.region ?? "其他" })
        return by.keys.sorted().map { ($0, by[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            courseList
                .navigationTitle("選擇所在球場")
                .toolbar { toolbarItems }
                .overlay { emptyOverlay }
                .sheet(isPresented: $showingCreate) { createSheet }
                .sheet(item: $editingPar) { entry in editSheet(for: entry) }
                .sheet(item: $pendingEntry) { entry in confirmSheet(for: entry) }
        }
    }

    private var courseList: some View {
        List {
            ForEach(grouped, id: \.region) { group in
                Section {
                    ForEach(group.courses) { entry in
                        CourseRow(entry: entry, onSelect: handleTap)
                            .listRowBackground(DS.cream.opacity(0.55))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                rowSwipeActions(for: entry)
                            }
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
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
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

    @ViewBuilder
    private var emptyOverlay: some View {
        if entries.isEmpty {
            ContentUnavailableView("找不到球場",
                                   systemImage: "flag.circle",
                                   description: Text("點右上「＋」新增你的球場"))
        }
    }

    private var createSheet: some View {
        CreateCourseView { listing in
            entries = CourseCatalog.entries()
            onSelect(listing.course)
        }
    }

    private func editSheet(for entry: CourseListing) -> some View {
        EditCourseParView(listing: entry) {
            entries = CourseCatalog.entries()
        }
    }

    private func confirmSheet(for entry: CourseListing) -> some View {
        // First-time pick on a bundled course: confirm pars, then enter
        // the round with the freshly-saved override applied.
        EditCourseParView(listing: entry) {
            entries = CourseCatalog.entries()
            let updated = entries.first { $0.course.id == entry.course.id }?.course
                ?? entry.course
            onSelect(updated)
        }
    }
}

private struct CourseRow: View {
    let entry: CourseListing
    let onSelect: (CourseListing) -> Void

    var body: some View {
        Button {
            onSelect(entry)
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
                                 par: entry.course.par,
                                 confirmed: CourseCatalog.isParConfirmed(
                                    courseID: entry.course.id))
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
    let confirmed: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text("\(holes) 洞")
                .foregroundStyle(.secondary)
            Text("·").foregroundStyle(.tertiary)
            if confirmed {
                Text("Par \(par)").foregroundStyle(.secondary)
            } else {
                Label("Par 未校正", systemImage: "exclamationmark.circle")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(DS.amber)
            }
        }
        .font(.caption.monospacedDigit())
    }
}
