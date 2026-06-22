import SwiftUI
import Core

struct HomeScreen: View {
    let database: DatabaseManager
    let translationService: TranslationService?
    let sentenceGenerator: SentenceGenerator?
    let ttsQueue: TTSGenerationQueue?
    let ttsPlayer: TTSPlayer

    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        LibraryView(
                            database: database,
                            translationService: translationService,
                            sentenceGenerator: sentenceGenerator,
                            ttsQueue: ttsQueue,
                            ttsPlayer: ttsPlayer
                        )
                    } label: {
                        Label("Library", systemImage: "rectangle.stack")
                    }
                }
            }
            .navigationTitle("Recall")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(database: database)
            }
        }
    }
}
