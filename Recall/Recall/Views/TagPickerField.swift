import SwiftUI
import Core

struct TagPickerField: View {
    let database: DatabaseManager
    @Binding var selectedTagIds: [Int64]
    var onFocusChange: ((Bool) -> Void)? = nil

    @State private var allTags: [Tag] = []
    @State private var searchText: String = ""
    @State private var isExpanded: Bool = false
    @FocusState private var isFocused: Bool

    private var tagRepo: TagRepository { TagRepository(database: database) }

    private var selectedTags: [Tag] {
        allTags.filter { selectedTagIds.contains($0.id ?? -1) }
    }

    private var filteredTags: [Tag] {
        (try? tagRepo.searchTags(matching: searchText)) ?? []
    }

    private var hasExactMatch: Bool {
        let folded = searchText.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return allTags.contains { tag in
            tag.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) == folded
        }
    }

    private var showCreateRow: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasExactMatch
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Chips + text field row
            VStack(alignment: .leading, spacing: 8) {
                if !selectedTags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(selectedTags) { tag in
                            TagChipView(tag: tag) {
                                selectedTagIds.removeAll { $0 == tag.id }
                            }
                        }
                    }
                }

                TextField(selectedTags.isEmpty ? "Add tags…" : "More tags…", text: $searchText)
                    .font(.system(size: 15))
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: isFocused) { _, focused in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isExpanded = focused
                        }
                        onFocusChange?(focused)
                    }
                    .onChange(of: searchText) { _, _ in
                        isExpanded = isFocused
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.accentColor.opacity(0.55) : Color.clear, lineWidth: 1.5)
            )

            // Dropdown
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(filteredTags) { tag in
                        let isSelected = selectedTagIds.contains(tag.id ?? -1)
                        Button {
                            toggleTag(tag)
                        } label: {
                            HStack {
                                Text(tag.name)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if tag.id != filteredTags.last?.id || showCreateRow {
                            Divider().padding(.leading, 14)
                        }
                    }

                    if showCreateRow {
                        Button {
                            createAndSelectTag()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.accentColor)
                                Text("Create \u{201C}\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D}")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.accentColor)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    if filteredTags.isEmpty && !showCreateRow {
                        Text("No tags found")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                .padding(.top, 4)
            }
        }
        .onAppear { loadTags() }
    }

    private func loadTags() {
        allTags = (try? tagRepo.fetchAll()) ?? []
    }

    private func toggleTag(_ tag: Tag) {
        guard let id = tag.id else { return }
        if selectedTagIds.contains(id) {
            selectedTagIds.removeAll { $0 == id }
        } else {
            selectedTagIds.append(id)
        }
        searchText = ""
    }

    private func createAndSelectTag() {
        let name = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        var newTag = Tag(name: name)
        try? tagRepo.insert(&newTag)
        loadTags()
        if let id = newTag.id {
            selectedTagIds.append(id)
        }
        searchText = ""
    }
}

// MARK: - FlowLayout helper

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposedViewSize(bounds.size), subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private struct ArrangeResult {
        var size: CGSize
        var frames: [CGRect]
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> ArrangeResult {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalHeight = y + rowHeight
        }

        return ArrangeResult(size: CGSize(width: maxWidth, height: totalHeight), frames: frames)
    }
}
