import SwiftUI
import Core

private extension CardProgress {
    enum FSRSState: Int {
        case new = 0, learning = 1, review = 2, relearning = 3

        var label: String {
            switch self {
            case .new: return "New"
            case .learning: return "Learning"
            case .review: return "Review"
            case .relearning: return "Relearning"
            }
        }

        var color: Color {
            switch self {
            case .new: return .blue
            case .learning: return Color(hue: 0.08, saturation: 0.9, brightness: 0.95)
            case .review: return Color(hue: 0.38, saturation: 0.75, brightness: 0.65)
            case .relearning: return Color(hue: 0.0, saturation: 0.8, brightness: 0.8)
            }
        }
    }

    var state: FSRSState { FSRSState(rawValue: fsrsState) ?? .new }

    var dueLabel: String {
        let calendar = Calendar.current
        let now = Date()
        if due <= now { return "Due now" }
        let days = calendar.dateComponents([.day], from: now, to: due).day ?? 0
        return days == 0 ? "Due today" : "in \(days)d"
    }

    var isDue: Bool { due <= Date() }
}

struct DeckDetailView: View {
    let database: DatabaseManager
    let translationService: TranslationService?
    let sentenceGenerator: SentenceGenerator?
    let ttsQueue: TTSGenerationQueue?
    let ttsPlayer: TTSPlayer
    @State private var deck: Deck
    @State private var cards: [Card] = []
    @State private var progressByCard: [Int64: CardProgress] = [:]
    @State private var showingCreateCard = false
    @State private var showingGenerateSentences = false
    @State private var editingCard: Card?
    @State private var statsCard: Card?
    @State private var showingRename = false
    @State private var renameDraft = ""

    init(
        database: DatabaseManager,
        deck: Deck,
        translationService: TranslationService?,
        sentenceGenerator: SentenceGenerator?,
        ttsQueue: TTSGenerationQueue?,
        ttsPlayer: TTSPlayer
    ) {
        self.database = database
        self.translationService = translationService
        self.sentenceGenerator = sentenceGenerator
        self.ttsQueue = ttsQueue
        self.ttsPlayer = ttsPlayer
        _deck = State(initialValue: deck)
    }

    private var dueCount: Int { progressByCard.values.filter { $0.isDue }.count }
    private var newCount: Int { progressByCard.values.filter { $0.state == .new }.count }

    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                if !cards.isEmpty {
                    statsRow
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 4, trailing: 20))
                        .listRowSeparator(.hidden)
                }

                ForEach(cards) { card in
                    cardRow(card, progress: progressByCard[card.id!])
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                        .listRowSeparator(.hidden)
                        .onTapGesture { statsCard = card }
                }
                .onDelete(perform: deleteCards)

                if !cards.isEmpty {
                    Color.clear
                        .frame(height: 80)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .background(Color(.systemGroupedBackground))
            .overlay {
                if cards.isEmpty {
                    ContentUnavailableView(
                        "No Cards Yet",
                        systemImage: "character.book.closed",
                        description: Text("Tap + to add your first card.")
                    )
                }
            }

            bottomActions
        }
        .navigationTitle(deck.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingCreateCard = true } label: {
                    Image(systemName: "plus").fontWeight(.semibold)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        renameDraft = deck.name
                        showingRename = true
                    } label: {
                        Label("Rename Deck", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingCreateCard) {
            CardCreationView(
                database: database,
                deck: deck,
                translationService: translationService,
                ttsQueue: ttsQueue,
                ttsPlayer: ttsPlayer
            )
            .onDisappear { loadCards() }
        }
        .sheet(isPresented: $showingGenerateSentences) {
            GenerationReviewSheet(
                database: database,
                deck: deck,
                sentenceGenerator: sentenceGenerator,
                ttsQueue: ttsQueue
            )
            .onDisappear { loadCards() }
        }
        .sheet(item: $editingCard) { card in
            CardEditView(
                database: database,
                deck: deck,
                translationService: translationService,
                ttsQueue: ttsQueue,
                ttsPlayer: ttsPlayer,
                card: card
            )
            .onDisappear { loadCards() }
        }
        .sheet(item: $statsCard) { card in
            CardStatsView(
                database: database,
                deck: deck,
                card: card,
                translationService: translationService,
                ttsQueue: ttsQueue,
                ttsPlayer: ttsPlayer
            )
            .onDisappear { loadCards() }
        }
        .alert("Rename Deck", isPresented: $showingRename) {
            TextField("Deck name", text: $renameDraft)
                .autocorrectionDisabled()
            Button("Cancel", role: .cancel) {}
            Button("Save") { renameDeck() }
                .disabled(renameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .onAppear { loadCards() }
    }

    private func renameDeck() {
        let trimmed = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != deck.name else { return }
        var updated = deck
        updated.name = trimmed
        let repo = DeckRepository(database: database)
        try? repo.update(&updated)
        deck = updated
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCell(value: "\(cards.count)", label: "Cards", color: .primary)
            statCell(value: "\(dueCount)", label: "Due", color: dueCount > 0 ? Color(hue: 0.08, saturation: 0.9, brightness: 0.95) : .secondary)
            statCell(value: "\(newCount)", label: "New", color: newCount > 0 ? .blue : .secondary)
            Spacer()
        }
    }

    private func statCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(width: 64, height: 52)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func cardRow(_ card: Card, progress: CardProgress?) -> some View {
        let state = progress?.state ?? .new
        let isDue = progress?.isDue ?? false

        return HStack(alignment: .center, spacing: 14) {
            Capsule()
                .fill(state.color)
                .frame(width: 3, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(card.sourceValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(card.targetValue)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text(state.label)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(state.color.opacity(0.12))
                    .foregroundStyle(state.color)
                    .clipShape(Capsule())

                HStack(spacing: 5) {
                    if let p = progress, p.reps > 0 {
                        Label("\(p.reps)", systemImage: "arrow.trianglehead.2.clockwise")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    if let p = progress {
                        Text(p.dueLabel)
                            .font(.system(size: 11))
                            .foregroundStyle(isDue ? AnyShapeStyle(Color(hue: 0.08, saturation: 0.9, brightness: 0.95)) : AnyShapeStyle(.tertiary))
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var bottomActions: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color(.systemGroupedBackground).opacity(0), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            VStack(spacing: 10) {
                Button { showingGenerateSentences = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Generate Sentences")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if !cards.isEmpty {
                    NavigationLink {
                        StudySetupView(database: database, decks: [deck], ttsPlayer: ttsPlayer)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                            Text("Study Deck")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .background(Color(.systemGroupedBackground))
        }
    }

    private func loadCards() {
        guard let deckId = deck.id else { return }
        let cardRepo = CardRepository(database: database)
        let progressRepo = CardProgressRepository(database: database)
        cards = (try? cardRepo.fetchAll(deckId: deckId)) ?? []
        var lookup: [Int64: CardProgress] = [:]
        for card in cards {
            guard let cardId = card.id else { continue }
            if let p = try? progressRepo.fetch(cardId: cardId, direction: .sourceToTarget) {
                lookup[cardId] = p
            }
        }
        progressByCard = lookup
    }

    private func deleteCards(at offsets: IndexSet) {
        let repo = CardRepository(database: database)
        for index in offsets {
            var card = cards[index]
            try? repo.softDelete(&card)
        }
        loadCards()
    }
}
