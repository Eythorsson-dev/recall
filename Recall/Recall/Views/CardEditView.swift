import SwiftUI
import Core

struct CardEditView: View {
    let database: DatabaseManager
    let deck: Deck
    let translationService: TranslationService?
    let ttsQueue: TTSGenerationQueue?
    let ttsPlayer: TTSPlayer
    let card: Card

    var body: some View {
        CardEditorView(
            mode: .edit(card),
            database: database,
            deck: deck,
            translationService: translationService,
            ttsQueue: ttsQueue,
            ttsPlayer: ttsPlayer
        )
    }
}
