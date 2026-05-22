import SwiftUI
import Core

@main
struct RecallApp: App {
    @State private var databaseManager: DatabaseManager?
    @State private var databaseError: Error?
    @State private var translationService: TranslationService?

    var body: some Scene {
        WindowGroup {
            if let db = databaseManager {
                LibraryView(database: db)
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
        } catch {
            databaseError = error
        }
    }
}
