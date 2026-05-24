import SwiftUI
import Core

struct CardCreationView: View {
    let database: DatabaseManager
    let deck: Deck
    let translationService: TranslationService?

    var body: some View {
        CardEditorView(
            mode: .create,
            database: database,
            deck: deck,
            translationService: translationService
        )
    }
}
