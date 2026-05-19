import SwiftUI
import Core

struct StudySetupView: View {
    let database: DatabaseManager
    @State private var direction: StudyDirection = .sourceToTarget
    @State private var dueCount = 0
    @State private var isStudying = false

    var body: some View {
        Form {
            Section("Due Cards") {
                Text("\(dueCount) card\(dueCount == 1 ? "" : "s") due for review")
                    .font(.headline)
            }

            Section("Study Direction") {
                Picker("Direction", selection: $direction) {
                    ForEach(StudyDirection.allCases, id: \.self) { dir in
                        Text(dir.displayName).tag(dir)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section {
                Button("Start Study Session") {
                    isStudying = true
                }
                .disabled(dueCount == 0)
                .frame(maxWidth: .infinity)
                .font(.headline)
            }
        }
        .navigationTitle("Study")
        .navigationDestination(isPresented: $isStudying) {
            StudySessionView(database: database, direction: direction)
        }
        .onAppear { loadDueCount() }
    }

    private func loadDueCount() {
        let repo = CardRepository(database: database)
        dueCount = (try? repo.fetchDue().count) ?? 0
    }
}
