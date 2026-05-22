import SwiftUI
import GolfCore

/// Correct a course's per-hole par against the real on-site scorecard.
/// The bundled seed ships a standard par template (Taiwan clubs don't
/// publish full scorecards); this sheet writes a per-course override
/// through `CourseCatalog.updatePars`.
struct EditCourseParView: View {
    let listing: CourseListing
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pars: [Int]

    init(listing: CourseListing, onSaved: @escaping () -> Void) {
        self.listing = listing
        self.onSaved = onSaved
        _pars = State(initialValue: listing.course.holes.map(\.par))
    }

    private var total: Int { pars.reduce(0, +) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("依現場記分卡把每洞 Par 改成真值,存檔後這座球場一律套用。",
                          systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("總桿")
                        Spacer()
                        Text("\(total)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(DS.fairway)
                    }
                }

                Section("每洞 Par") {
                    ForEach(pars.indices, id: \.self) { i in
                        Stepper(value: parBinding(i), in: 3...6) {
                            HStack {
                                Text("第 \(i + 1) 洞")
                                Spacer()
                                Text("Par \(pars[i])").monospacedDigit()
                            }
                        }
                        .accessibilityIdentifier("editpar.hole.\(i + 1)")
                    }
                }
            }
            .navigationTitle(listing.course.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        CourseCatalog.updatePars(courseID: listing.course.id, pars: pars)
                        onSaved()
                        dismiss()
                    } label: {
                        Text("儲存").fontWeight(.semibold)
                    }
                    .accessibilityIdentifier("editpar.save")
                }
            }
        }
    }

    private func parBinding(_ index: Int) -> Binding<Int> {
        Binding(get: { pars[index] }, set: { pars[index] = $0 })
    }
}
