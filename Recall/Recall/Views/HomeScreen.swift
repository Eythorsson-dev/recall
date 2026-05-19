import SwiftUI
import Core

struct HomeScreen: View {
    let database: DatabaseManager

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        LibraryView(database: database)
                    } label: {
                        Label("Library", systemImage: "rectangle.stack")
                    }
                }
            }
            .navigationTitle("Recall")
        }
    }
}
