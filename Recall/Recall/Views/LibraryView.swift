import SwiftUI
import Core

struct LibraryView: View {
    let database: DatabaseManager
    let translationService: TranslationService?
    @State private var decks: [Deck] = []
    @State private var showingCreateDeck = false
    @State private var showingStudySetup = false

    var body: some View {
        NavigationStack {
            Group {
                if decks.isEmpty {
                    ContentUnavailableView("No Decks Yet", systemImage: "rectangle.stack", description: Text("Tap + to create your first deck."))
                } else {
                    List {
                        ForEach(decks) { deck in
                            NavigationLink {
                                DeckDetailView(database: database, deck: deck, translationService: translationService)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(deck.name)
                                        .font(.headline)
                                    Text("\(deck.sourceField) → \(deck.targetField)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .onDelete(perform: deleteDecks)
                    }
                }
            }
            .navigationTitle("Recall")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingCreateDeck = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showingStudySetup = true
                    } label: {
                        Label("Study", systemImage: "brain.head.profile")
                    }
                    .disabled(decks.isEmpty)
                }
            }
            .sheet(isPresented: $showingCreateDeck) {
                DeckCreationView(database: database)
                    .onDisappear { loadDecks() }
            }
            .sheet(isPresented: $showingStudySetup) {
                StudySetupView(database: database, decks: decks)
            }
            .onAppear { loadDecks() }
        }
    }

    private func loadDecks() {
        let repo = DeckRepository(database: database)
        decks = (try? repo.fetchAll()) ?? []
    }

    private func deleteDecks(at offsets: IndexSet) {
        let repo = DeckRepository(database: database)
        for index in offsets {
            var deck = decks[index]
            try? repo.softDelete(&deck)
        }
        loadDecks()
    }
}
