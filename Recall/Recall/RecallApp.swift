import SwiftUI
import Core

@main
struct RecallApp: App {
    @State private var databaseManager: DatabaseManager?
    @State private var databaseError: Error?
    @State private var translationService: TranslationService?
    @State private var sentenceGenerator: SentenceGenerator?
    @State private var ttsQueue: TTSGenerationQueue?
    @State private var ttsPlayer: TTSPlayer?

    var body: some Scene {
        WindowGroup {
            if let db = databaseManager, let player = ttsPlayer {
                LibraryView(
                    database: db,
                    translationService: translationService,
                    sentenceGenerator: sentenceGenerator,
                    ttsQueue: ttsQueue,
                    ttsPlayer: player
                )
            } else if let error = databaseError {
                Text("Database error: \(error.localizedDescription)")
            } else {
                ProgressView("Loading…")
                    .task { await initializeApp() }
            }
        }
    }

    private func initializeApp() async {
        do {
            let url = URL.documentsDirectory.appending(path: "recall.sqlite")
            let db = try DatabaseManager(path: url.path())
            databaseManager = db

            let cache = try AudioCache()
            let fallback = AVSpeechSynthesizerFallback()
            ttsPlayer = TTSPlayer(cache: cache, fallback: fallback)

            if let apiKey = bundleString("GoogleTranslationAPIKey") {
                translationService = TranslationService(apiKey: apiKey)
            }

            if let geminiKey = bundleString("GeminiAPIKey") {
                sentenceGenerator = SentenceGenerator(
                    client: GeminiClient(apiKey: geminiKey),
                    knownVocabulary: KnownVocabularyQuery(database: db),
                    recentSentences: RecentSentencesQuery(database: db)
                )
            }

            // Same Google Cloud project can serve both APIs — fall back to the
            // translation key if a dedicated TTS key wasn't supplied.
            if let ttsKey = bundleString("GoogleCloudTTSAPIKey") ?? bundleString("GoogleTranslationAPIKey") {
                let client = GoogleCloudTTSClient(apiKey: ttsKey)
                let queue = TTSGenerationQueue(database: db, cache: cache, tts: client)
                ttsQueue = queue
                // Drain anything still pending from a previous launch.
                Task.detached(priority: .utility) {
                    try? await queue.processPending()
                }
            }
        } catch {
            databaseError = error
        }
    }

    private func bundleString(_ key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty else { return nil }
        return value
    }
}
