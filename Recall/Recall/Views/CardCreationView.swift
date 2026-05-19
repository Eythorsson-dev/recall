import SwiftUI
import Core

struct CardCreationView: View {
    let database: DatabaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var language = ""
    @State private var sourceField = ""
    @State private var targetField = ""
    @State private var sourceValue = ""
    @State private var targetValue = ""
    @State private var sourceSpeakable = false
    @State private var targetSpeakable = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Language") {
                    TextField("Language (e.g. Ukrainian)", text: $language)
                        .textInputAutocapitalization(.words)
                }

                Section("Fields") {
                    TextField("Source field name (e.g. Ukrainian)", text: $sourceField)
                    TextField("Target field name (e.g. English)", text: $targetField)
                }

                Section("Content") {
                    TextField("Source value", text: $sourceValue)
                    TextField("Target value", text: $targetValue)
                }

                Section("Audio") {
                    Toggle("Source speakable", isOn: $sourceSpeakable)
                    Toggle("Target speakable", isOn: $targetSpeakable)
                }
            }
            .navigationTitle("New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCard() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !language.isEmpty && !sourceField.isEmpty && !targetField.isEmpty
            && !sourceValue.isEmpty && !targetValue.isEmpty
    }

    private func saveCard() {
        let repo = CardRepository(database: database)
        var card = Card(
            language: language,
            sourceField: sourceField,
            targetField: targetField,
            sourceValue: sourceValue,
            targetValue: targetValue,
            sourceSpeakable: sourceSpeakable,
            targetSpeakable: targetSpeakable
        )
        try? repo.insert(&card)
        dismiss()
    }
}
