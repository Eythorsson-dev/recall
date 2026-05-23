import SwiftUI
import Core

struct CardEditView: View {
    let database: DatabaseManager
    let deck: Deck
    let translationService: TranslationService?
    let card: Card
    @Environment(\.dismiss) private var dismiss

    @State private var sourceValue: String
    @State private var targetValue: String
    @State private var targetValueIsUserModified: Bool
    @State private var isTranslating = false
    @State private var translationFailed = false

    @FocusState private var focusedField: Field?

    private enum Field: Hashable { case source, target }

    init(database: DatabaseManager, deck: Deck, translationService: TranslationService?, card: Card) {
        self.database = database
        self.deck = deck
        self.translationService = translationService
        self.card = card
        _sourceValue = State(initialValue: card.sourceValue)
        _targetValue = State(initialValue: card.targetValue)
        _targetValueIsUserModified = State(initialValue: card.targetValueIsUserModified)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(deck.sourceField, text: $sourceValue)
                        .focused($focusedField, equals: .source)
                    HStack {
                        TextField(deck.targetField, text: $targetValue)
                            .focused($focusedField, equals: .target)
                            .foregroundStyle(isTargetMuted ? Color.secondary : Color.primary)
                        if isTranslating {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                } header: {
                    Text("\(deck.sourceField) → \(deck.targetField)")
                } footer: {
                    if translationFailed {
                        Text("Translation failed — enter manually")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Card")
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
            .onChange(of: focusedField) { oldValue, _ in
                if oldValue == .source {
                    triggerTranslation()
                }
            }
            .onChange(of: targetValue) { _, newValue in
                if newValue.isEmpty {
                    targetValueIsUserModified = false
                } else if focusedField == .target {
                    targetValueIsUserModified = true
                    translationFailed = false
                }
            }
        }
    }

    private var isTargetMuted: Bool {
        !targetValueIsUserModified && !targetValue.isEmpty
    }

    private var isValid: Bool {
        !sourceValue.isEmpty && !targetValue.isEmpty && !isTranslating
    }

    private func triggerTranslation() {
        guard !targetValueIsUserModified,
              !sourceValue.isEmpty,
              let service = translationService else { return }

        isTranslating = true
        translationFailed = false

        Task {
            do {
                let result = try await service.translate(
                    sourceValue,
                    from: deck.sourceLanguage,
                    to: deck.targetLanguage
                )
                guard !targetValueIsUserModified else {
                    isTranslating = false
                    return
                }
                targetValue = result
                targetValueIsUserModified = false
            } catch {
                translationFailed = true
            }
            isTranslating = false
        }
    }

    private func saveCard() {
        let repo = CardRepository(database: database)
        var updated = card
        updated.sourceValue = sourceValue
        updated.targetValue = targetValue
        updated.targetValueIsUserModified = targetValueIsUserModified
        try? repo.update(&updated)
        dismiss()
    }
}
