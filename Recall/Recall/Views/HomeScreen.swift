import SwiftUI
import Core

struct HomeScreen: View {
    let database: DatabaseManager
    let translationService: TranslationService?
    let sentenceGenerator: SentenceGenerator?
    let ttsQueue: TTSGenerationQueue?
    let ttsPlayer: TTSPlayer

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
        }
    }
}
