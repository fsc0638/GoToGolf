import SwiftUI
import GolfCore

/// Quick add-your-course flow. Stores into the local user catalog
/// (UserDefaults) via `CourseCatalog.addUserCourse`. Default par is 4 for
/// every hole — user adjusts only the ones that differ.
struct CreateCourseView: View {
    let onCreated: (CourseListing) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var region = ""
    @State private var holeCount = 18
    @State private var pars: [Int] = Array(repeating: 4, count: 18)

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本資料") {
                    TextField("球場名稱", text: $name)
                        .accessibilityIdentifier("create.name")
                    TextField("地區（縣市，選填）", text: $region)
                    Picker("洞數", selection: $holeCount) {
                        Text("9").tag(9)
                        Text("18").tag(18)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: holeCount) { _, new in
                        pars = Array(repeating: 4, count: new)
                    }
                }

                Section("每洞 Par（預設 4，依實際調整）") {
                    ForEach(0..<holeCount, id: \.self) { i in
                        Stepper(value: parBinding(i), in: 3...6) {
                            HStack {
                                Text("第 \(i + 1) 洞")
                                Spacer()
                                Text("Par \(pars[i])").monospacedDigit()
                            }
                        }
                    }
                }
            }
            .navigationTitle("新增球場")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") {
                        let trimmedRegion = region.trimmingCharacters(in: .whitespaces)
                        if let listing = CourseCatalog.addUserCourse(
                            name: name.trimmingCharacters(in: .whitespaces),
                            region: trimmedRegion.isEmpty ? nil : trimmedRegion,
                            pars: pars
                        ) {
                            onCreated(listing)
                            dismiss()
                        }
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier("create.save")
                }
            }
        }
    }

    private func parBinding(_ index: Int) -> Binding<Int> {
        Binding(get: { pars[index] }, set: { pars[index] = $0 })
    }
}
