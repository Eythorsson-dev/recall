import SwiftUI
import Core

@main
struct RecallApp: App {
    @State private var databaseManager: DatabaseManager?
    @State private var databaseError: Error?
    @State private var translationService: TranslationService?
    @State private var sentenceGenerator: SentenceGenerator?

    var body: some Scene {
        WindowGroup {
            if let db = databaseManager {
                LibraryView(database: db, translationService: translationService, sentenceGenerator: sentenceGenerator)
            } else if let error = databaseError {
                Text("Database error: \(error.localizedDescription)")
            } else {
                ProgressView("Loading…")
                    .task { await initializeDatabase() }
            }
        }
    }

    private func initializeDatabase() async {
        do {
            let url = URL.documentsDirectory.appending(path: "recall.sqlite")
            databaseManager = try DatabaseManager(path: url.path())
            if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleTranslationAPIKey") as? String,
               !apiKey.isEmpty {
                translationService = TranslationService(apiKey: apiKey)
            }
            if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GeminiAPIKey") as? String,
               !apiKey.isEmpty {
                sentenceGenerator = SentenceGenerator(client: GeminiClient(apiKey: apiKey))
            }
        } catch {
            databaseError = error
        }
    }
}
