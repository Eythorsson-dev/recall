import SwiftUI
import Core

struct SentencePair: Identifiable, Hashable {
    let id = UUID()
    let source: String
    let target: String
}

struct GenerationReviewSheet: View {
    let database: DatabaseManager
    let deck: Deck

    @Environment(\.dismiss) private var dismiss
    @State private var pending: [SentencePair] = []

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                List {
                    Section {
                        ForEach(pending) { pair in
                            sentenceRow(pair)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                                .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteRows)
                    }

                    Color.clear
                        .frame(height: 80)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .background(Color(.systemGroupedBackground))
                .overlay {
                    if pending.isEmpty {
                        ContentUnavailableView(
                            "No Sentences",
                            systemImage: "text.bubble",
                            description: Text("All pending sentences were removed.")
                        )
                    }
                }

                acceptBar
            }
            .navigationTitle("Generate Sentences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
            .onAppear {
                if pending.isEmpty {
                    pending = fixtureSentences(for: deck.targetLanguage)
                }
            }
        }
    }

    private func sentenceRow(_ pair: SentencePair) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(pair.source)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
            Text(pair.target)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var acceptBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color(.systemGroupedBackground).opacity(0), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            Button {
                acceptAll()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                    Text("Accept all")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(pending.isEmpty ? AnyShapeStyle(Color.secondary.opacity(0.35)) : AnyShapeStyle(Color.accentColor))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
            }
            .disabled(pending.isEmpty)
            .padding(.bottom, 12)
            .background(Color(.systemGroupedBackground))
        }
    }

    private func deleteRows(at offsets: IndexSet) {
        pending.remove(atOffsets: offsets)
    }

    private func acceptAll() {
        guard let deckId = deck.id, !pending.isEmpty else { return }
        let repo = CardRepository(database: database)
        for pair in pending {
            var card = Card(
                deckId: deckId,
                sourceValue: pair.source,
                targetValue: pair.target,
                targetValueIsUserModified: true,
                kind: .sentence
            )
            try? repo.insert(&card)
        }
        dismiss()
    }
}

private func fixtureSentences(for targetLanguage: Language) -> [SentencePair] {
    switch targetLanguage {
    case .ukrainian:
        return [
            SentencePair(source: "I love coffee in the morning.", target: "Я люблю каву вранці."),
            SentencePair(source: "Where is the bathroom?", target: "Де туалет?"),
            SentencePair(source: "Thank you very much.", target: "Дуже дякую."),
            SentencePair(source: "How much does this cost?", target: "Скільки це коштує?"),
            SentencePair(source: "I don't understand.", target: "Я не розумію.")
        ]
    case .norwegian:
        return [
            SentencePair(source: "I love coffee in the morning.", target: "Jeg elsker kaffe om morgenen."),
            SentencePair(source: "Where is the bathroom?", target: "Hvor er toalettet?"),
            SentencePair(source: "Thank you very much.", target: "Tusen takk."),
            SentencePair(source: "How much does this cost?", target: "Hvor mye koster dette?"),
            SentencePair(source: "I don't understand.", target: "Jeg forstår ikke.")
        ]
    case .english:
        return [
            SentencePair(source: "Доброго ранку!", target: "Good morning!"),
            SentencePair(source: "Як справи?", target: "How are you?"),
            SentencePair(source: "Я з України.", target: "I am from Ukraine."),
            SentencePair(source: "До зустрічі завтра.", target: "See you tomorrow."),
            SentencePair(source: "Я хочу їсти.", target: "I am hungry.")
        ]
    }
}
