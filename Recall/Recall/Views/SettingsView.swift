import SwiftUI
import Core

struct SettingsView: View {
    let database: DatabaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var tags: [Tag] = []
    @State private var editingTagId: Int64? = nil
    @State private var renameDraft: String = ""

    private var tagRepo: TagRepository { TagRepository(database: database) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if tags.isEmpty {
                        Text("No tags yet. Create tags from the card editor.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(tags) { tag in
                            tagRow(tag)
                        }
                        .onDelete(perform: deleteTags)
                    }
                } header: {
                    Text("Tags")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { loadTags() }
        }
    }

    @ViewBuilder
    private func tagRow(_ tag: Tag) -> some View {
        if editingTagId == tag.id {
            HStack {
                TextField("Tag name", text: $renameDraft)
                    .font(.system(size: 16))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit { commitRename(tag) }

                Spacer()

                Button("Save") { commitRename(tag) }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .disabled(renameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } else {
            HStack {
                Text(tag.name)
                    .font(.system(size: 16))
                Spacer()
                Button {
                    renameDraft = tag.name
                    editingTagId = tag.id
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func commitRename(_ tag: Tag) {
        let trimmed = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var updated = tag
        updated.name = trimmed
        try? tagRepo.update(&updated)
        editingTagId = nil
        loadTags()
    }

    private func deleteTags(at offsets: IndexSet) {
        let settingsRepo = SettingsRepository(database: database)
        var savedIds = (try? settingsRepo.selectedTagIds()) ?? []
        for index in offsets {
            let tag = tags[index]
            try? tagRepo.delete(tag)
            if let tagId = tag.id {
                savedIds.removeAll { $0 == tagId }
            }
        }
        try? settingsRepo.setSelectedTagIds(savedIds)
        loadTags()
    }

    private func loadTags() {
        tags = (try? tagRepo.fetchAll()) ?? []
    }
}
