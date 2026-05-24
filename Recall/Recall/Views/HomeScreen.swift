import SwiftUI
import Core

struct HomeScreen: View {
    let database: DatabaseManager
    let translationService: TranslationService?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        LibraryView(database: database, translationService: translationService)
                    } label: {
                        Label("Library", systemImage: "rectangle.stack")
                    }
                }
            }
            .navigationTitle("Recall")
        }
    }
}
