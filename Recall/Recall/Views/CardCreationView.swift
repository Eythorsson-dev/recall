import SwiftUI
import Core

struct CardCreationView: View {
    let database: DatabaseManager
    let deck: Deck
    let translationService: TranslationService?
    let ttsQueue: TTSGenerationQueue?
    let ttsPlayer: TTSPlayer

    var body: some View {
        CardEditorView(
            mode: .create,
            database: database,
            deck: deck,
            translationService: translationService,
            ttsQueue: ttsQueue,
            ttsPlayer: ttsPlayer
        )
    }
}
