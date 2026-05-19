import SwiftUI
import Core

struct LibraryView: View {
    let database: DatabaseManager
    @State private var cards: [Card] = []
    @State private var showingCreateCard = false

    var body: some View {
        Group {
            if cards.isEmpty {
                ContentUnavailableView("No Cards Yet", systemImage: "rectangle.stack", description: Text("Tap + to create your first card."))
            } else {
                List {
                    ForEach(cards) { card in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.sourceValue)
                                .font(.headline)
                            Text(card.targetValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack {
                                Text(card.language)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Spacer()
                                Text(stateLabel(card.fsrsState))
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.fill.tertiary)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete(perform: deleteCards)
                }
            }
        }
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingCreateCard = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateCard) {
            CardCreationView(database: database)
                .onDisappear { loadCards() }
        }
        .onAppear { loadCards() }
    }

    private func stateLabel(_ state: Int) -> String {
        switch state {
        case 0: return "New"
        case 1: return "Learning"
        case 2: return "Review"
        case 3: return "Relearning"
        default: return "Unknown"
        }
    }

    private func loadCards() {
        let repo = CardRepository(database: database)
        cards = (try? repo.fetchAll()) ?? []
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
