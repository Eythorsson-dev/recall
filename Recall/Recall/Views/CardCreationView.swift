import SwiftUI
import Core

struct CardCreationView: View {
    let database: DatabaseManager
    let deck: Deck
    @Environment(\.dismiss) private var dismiss

    @State private var sourceValue = ""
    @State private var targetValue = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(deck.sourceField, text: $sourceValue)
                    TextField(deck.targetField, text: $targetValue)
                } header: {
                    Text("\(deck.sourceField) → \(deck.targetField)")
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
        !sourceValue.isEmpty && !targetValue.isEmpty
    }

    private func saveCard() {
        guard let deckId = deck.id else { return }
        let repo = CardRepository(database: database)
        var card = Card(
            deckId: deckId,
            sourceValue: sourceValue,
            targetValue: targetValue
        )
        try? repo.insert(&card)
        dismiss()
    }
}
