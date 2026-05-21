import SwiftUI
import Core

struct StudySetupView: View {
    let database: DatabaseManager
    let decks: [Deck]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDeckIds: Set<Int64> = []
    @State private var direction: StudyDirection? = nil
    @State private var studyMode: StudyMode = .reading
    @State private var dueCount = 0
    @State private var totalCount = 0
    @State private var isStudying = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    deckSection
                    directionSection
                    studyModeSection
                    statsSection
                    beginButton
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Study Session")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $isStudying) {
                StudySessionView(
                    database: database,
                    deckLookup: deckLookup,
                    selectedDeckIds: Array(selectedDeckIds),
                    direction: direction,
                    studyMode: studyMode
                )
            }
            .onChange(of: selectedDeckIds) { loadDueCount() }
            .onChange(of: direction) { loadDueCount() }
            .onAppear {
                selectedDeckIds = Set(decks.compactMap(\.id))
                loadDueCount()
            }
        }
    }

    // MARK: - Sections

    private var deckSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Decks")
            VStack(spacing: 1) {
                ForEach(decks) { deck in
                    deckRow(deck)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)
        }
    }

    private var directionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Direction")
                .padding(.top, 30)
            DirectionPicker(selection: $direction)
                .padding(.horizontal, 20)
        }
    }

    private var studyModeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Study Mode")
                .padding(.top, 30)
            StudyModePicker(selection: $studyMode)
                .padding(.horizontal, 20)
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if totalCount == 0 {
                Text("No cards\nselected")
                    .font(.system(size: 52, weight: .ultraLight, design: .serif))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            } else if dueCount > 0 {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(dueCount)")
                        .font(.system(size: 76, weight: .thin, design: .rounded))
                        .foregroundStyle(.tint)
                        .contentTransition(.numericText())
                    Text("/ \(totalCount)")
                        .font(.system(size: 30, weight: .thin, design: .rounded))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
                Text("cards due for review")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
            } else {
                Text("\(totalCount)")
                    .font(.system(size: 76, weight: .thin, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                Text("all caught up · practice all cards")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 38)
        .animation(.easeInOut(duration: 0.25), value: dueCount)
        .animation(.easeInOut(duration: 0.25), value: totalCount)
    }

    private var beginButton: some View {
        Button {
            isStudying = true
        } label: {
            HStack(spacing: 10) {
                Text("Begin Session")
                    .font(.system(size: 17, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(totalCount > 0 ? .white : Color.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(totalCount > 0 ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(totalCount == 0)
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 36)
        .padding(.bottom, 44)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.8)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 26)
            .padding(.bottom, 10)
    }

    @ViewBuilder
    private func deckRow(_ deck: Deck) -> some View {
        let id = deck.id!
        let isSelected = selectedDeckIds.contains(id)

        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                if isSelected { selectedDeckIds.remove(id) }
                else { selectedDeckIds.insert(id) }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.clear)
                        .frame(width: 22, height: 22)
                    Circle()
                        .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(deck.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                    Text("\(deck.sourceField) → \(deck.targetField)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? Color.accentColor.opacity(0.6) : Color.secondary.opacity(0.25))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .background(isSelected ? Color.accentColor.opacity(0.10) : Color(.secondarySystemGroupedBackground))
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var deckLookup: [Int64: Deck] {
        Dictionary(uniqueKeysWithValues: decks.compactMap { deck in
            deck.id.map { ($0, deck) }
        })
    }

    private func loadDueCount() {
        let progressRepo = CardProgressRepository(database: database)
        let ids = Array(selectedDeckIds)
        dueCount   = (try? progressRepo.fetchDueCount(deckIds: ids, direction: direction)) ?? 0
        totalCount = (try? progressRepo.fetchCardCount(deckIds: ids)) ?? 0
    }
}

// MARK: - Study Mode Picker

private struct StudyModePicker: View {
    @Binding var selection: StudyMode

    private struct Option: Identifiable {
        let id: Int
        let label: String
        let value: StudyMode
    }

    private let options: [Option] = [
        Option(id: 0, label: "Reading",   value: .reading),
        Option(id: 1, label: "With Text", value: .listeningWithText),
        Option(id: 2, label: "No Text",   value: .listeningWithoutText)
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                modeButton(option)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func modeButton(_ option: Option) -> some View {
        let isActive = selection == option.value
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                selection = option.value
            }
        } label: {
            Text(option.label)
                .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? .white : Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if isActive {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.accentColor)
                                .padding(3)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Direction Picker

private struct DirectionPicker: View {
    @Binding var selection: StudyDirection?

    private struct Option: Identifiable {
        let id: Int
        let label: String
        let value: StudyDirection?
    }

    private let options: [Option] = [
        Option(id: 0, label: "Forward", value: .sourceToTarget),
        Option(id: 1, label: "Reverse", value: .targetToSource),
        Option(id: 2, label: "Both",    value: nil)
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                dirButton(option)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func dirButton(_ option: Option) -> some View {
        let isActive = selection == option.value
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                selection = option.value
            }
        } label: {
            Text(option.label)
                .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? .white : Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if isActive {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.accentColor)
                                .padding(3)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}
