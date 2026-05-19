import SwiftUI
import Core

struct HomeScreen: View {
    let database: DatabaseManager

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink("Library") {
                        Text("Library — coming in Slice 2")
                    }
                    NavigationLink("Study") {
                        Text("Study Session — coming in Slice 2")
                    }
                }
            }
            .navigationTitle("Recall")
        }
    }
}
