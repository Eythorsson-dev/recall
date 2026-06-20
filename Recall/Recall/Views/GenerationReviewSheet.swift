import SwiftUI
import Core

struct GenerationReviewSheet: View {
    let database: DatabaseManager
    let deck: Deck
    let sentenceGenerator: SentenceGenerator?
    let ttsQueue: TTSGenerationQueue?

    @Environment(\.dismiss) private var dismiss
    @State private var batch = PendingGenerationBatch(sentences: [])
    @State private var phase: Phase = .idle
    @State private var errorMessage: String?

    private enum Phase {
        case idle
        case loading
        case loaded
        case failed
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                List {
                    Section {
                        ForEach(Array(batch.sentences.indices), id: \.self) { index in
                            sentenceRow(batch.sentences[index])
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
                .overlay { overlayContent }

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
            .task {
                guard phase == .idle else { return }
                await loadSentences()
            }
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch phase {
        case .idle, .loading:
            VStack(spacing: 12) {
                ProgressView()
                Text("Generating sentences…")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        case .failed:
            ContentUnavailableView(
                "Couldn't Generate",
                systemImage: "exclamationmark.triangle",
                description: Text(errorMessage ?? "Something went wrong.")
            )
        case .loaded where batch.sentences.isEmpty:
            ContentUnavailableView(
                "No Sentences",
                systemImage: "text.bubble",
                description: Text("All pending sentences were removed.")
            )
        case .loaded:
            EmptyView()
        }
    }

    private func sentenceRow(_ sentence: GeneratedSentence) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(sentence.source)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
            Text(sentence.target)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var newWordsFooterText: String? {
        let words = batch.activeNewWords
        guard !words.isEmpty else { return nil }
        let list = words.map(\.source).joined(separator: ", ")
        let pluralized = words.count == 1 ? "new word" : "new words"
        return "Adding \(words.count) \(pluralized): \(list)"
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

            if let footer = newWordsFooterText {
                Text(footer)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    .background(Color(.systemGroupedBackground))
            }

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
                .background(batch.sentences.isEmpty ? AnyShapeStyle(Color.secondary.opacity(0.35)) : AnyShapeStyle(Color.accentColor))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
            }
            .disabled(batch.sentences.isEmpty)
            .padding(.bottom, 12)
            .background(Color(.systemGroupedBackground))
        }
    }

    private func deleteRows(at offsets: IndexSet) {
        batch.remove(atOffsets: offsets)
    }

    private func acceptAll() {
        guard let deckId = deck.id, !batch.sentences.isEmpty else { return }
        var cards = batch.materializeCards(deckId: deckId)
        do {
            try CardRepository(database: database).insertAll(&cards)
        } catch {
            errorMessage = "Couldn't save: \(error.localizedDescription)"
            phase = .failed
            return
        }
        for card in cards {
            enqueueTTS(forCard: card)
        }
        if let queue = ttsQueue {
            Task.detached(priority: .utility) {
                try? await queue.processPending()
            }
        }
        dismiss()
    }

    private func enqueueTTS(forCard card: Card) {
        guard let queue = ttsQueue, let cardId = card.id else { return }
        if deck.sourceSpeakable {
            try? queue.enqueue(
                cardId: cardId,
                fieldSide: .source,
                text: card.sourceValue,
                language: deck.sourceLanguage
            )
        }
        if deck.targetSpeakable {
            try? queue.enqueue(
                cardId: cardId,
                fieldSide: .target,
                text: card.targetValue,
                language: deck.targetLanguage
            )
        }
    }

    private func loadSentences() async {
        phase = .loading
        guard let generator = sentenceGenerator else {
            errorMessage = "GEMINI_API_KEY is not configured. Add it to Secrets.xcconfig."
            phase = .failed
            return
        }
        do {
            let result = try await generator.generate(deck: deck)
            batch = PendingGenerationBatch(sentences: result.sentences)
            phase = .loaded
        } catch {
            errorMessage = String(describing: error)
            phase = .failed
        }
    }
}
