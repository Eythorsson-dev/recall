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
                    NavigationLink {
                        StudySetupView(database: database)
                    } label: {
                        Label("Study", systemImage: "brain.head.profile")
                    }
                }
            }
            .navigationTitle("Recall")
        }
    }
}
