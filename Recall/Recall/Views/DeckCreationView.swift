import SwiftUI
import Core

struct DeckCreationView: View {
    let database: DatabaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var sourceLanguage: Language = .ukrainian
    @State private var targetLanguage: Language = .english
    @State private var sourceSpeakable = false
    @State private var targetSpeakable = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Deck name", text: $name)
                }

                Section("Languages") {
                    Picker("From", selection: $sourceLanguage) {
                        ForEach(Language.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    Picker("To", selection: $targetLanguage) {
                        ForEach(Language.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                }

                Section("Audio") {
                    Toggle("\(sourceLanguage.displayName) speakable", isOn: $sourceSpeakable)
                    Toggle("\(targetLanguage.displayName) speakable", isOn: $targetSpeakable)
                }
            }
            .navigationTitle("New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveDeck() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !name.isEmpty && sourceLanguage != targetLanguage
    }

    private func saveDeck() {
        let repo = DeckRepository(database: database)
        var deck = Deck(
            name: name,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            sourceSpeakable: sourceSpeakable,
            targetSpeakable: targetSpeakable
        )
        try? repo.insert(&deck)
        dismiss()
    }
}
