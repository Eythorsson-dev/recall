import SwiftUI
import Core

struct CardEditorView: View {
    enum Mode {
        case create
        case edit(Card)

        var isEdit: Bool {
            if case .edit = self { return true }
            return false
        }

        var eyebrow: String { isEdit ? "Editing" : "New Card" }
        var primaryActionTitle: String { isEdit ? "Save Changes" : "Add Card" }
        var primaryActionIcon: String { isEdit ? "checkmark" : "plus" }
    }

    let mode: Mode
    let database: DatabaseManager
    let deck: Deck
    let translationService: TranslationService?
    let ttsQueue: TTSGenerationQueue?
    let ttsPlayer: TTSPlayer

    @Environment(\.dismiss) private var dismiss

    @State private var sourceValue: String = ""
    @State private var targetValue: String = ""
    @State private var targetValueIsUserModified: Bool = false
    @State private var isTranslating = false
    @State private var translationFailed = false
    @State private var translationDebounceTask: Task<Void, Never>?

    @FocusState private var focusedField: FieldKey?

    private enum FieldKey: Hashable { case source, target }

    init(
        mode: Mode,
        database: DatabaseManager,
        deck: Deck,
        translationService: TranslationService?,
        ttsQueue: TTSGenerationQueue?,
        ttsPlayer: TTSPlayer
    ) {
        self.mode = mode
        self.database = database
        self.deck = deck
        self.translationService = translationService
        self.ttsQueue = ttsQueue
        self.ttsPlayer = ttsPlayer
        if case .edit(let existing) = mode {
            _sourceValue = State(initialValue: existing.sourceValue)
            _targetValue = State(initialValue: existing.targetValue)
            _targetValueIsUserModified = State(initialValue: existing.targetValueIsUserModified)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        fields
                    }
                    .padding(.bottom, 132)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(Color(.systemGroupedBackground))

                actionBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
            .onAppear {
                if case .create = mode {
                    // Slight delay lets the modal finish presenting before keyboard rises.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        focusedField = .source
                    }
                }
            }
            .onChange(of: focusedField) { oldValue, _ in
                if oldValue == .source {
                    translationDebounceTask?.cancel()
                    triggerTranslation()
                }
            }
            .onChange(of: sourceValue) { _, _ in
                translationDebounceTask?.cancel()
                translationDebounceTask = Task {
                    try? await Task.sleep(for: .milliseconds(800))
                    guard !Task.isCancelled else { return }
                    triggerTranslation()
                }
            }
            .onChange(of: targetValue) { _, newValue in
                if newValue.isEmpty {
                    targetValueIsUserModified = false
                } else if focusedField == .target {
                    targetValueIsUserModified = true
                    translationFailed = false
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(mode.eyebrow.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.0)
                .foregroundStyle(.secondary)

            Rectangle()
                .fill(Color.primary.opacity(0.65))
                .frame(width: 28, height: 1)
                .padding(.top, 8)
                .padding(.bottom, 16)

            Text(deck.name)
                .font(.system(size: 32, weight: .regular, design: .serif))
                .foregroundStyle(.primary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Text(deck.sourceField.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(.tertiary)
                Image(systemName: "arrow.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary)
                Text(deck.targetField.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 36)
    }

    // MARK: - Fields

    private var fields: some View {
        VStack(spacing: 14) {
            fieldCard(
                key: .source,
                label: deck.sourceField,
                value: $sourceValue,
                isSpeakable: deck.sourceSpeakable,
                language: deck.sourceLanguage,
                isMuted: false,
                showTranslating: false,
                footer: nil
            )

            fieldCard(
                key: .target,
                label: deck.targetField,
                value: $targetValue,
                isSpeakable: deck.targetSpeakable,
                language: deck.targetLanguage,
                isMuted: isTargetMuted,
                showTranslating: isTranslating,
                footer: translationFailed ? "Translation failed — enter manually" : nil
            )
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func fieldCard(
        key: FieldKey,
        label: String,
        value: Binding<String>,
        isSpeakable: Bool,
        language: Language,
        isMuted: Bool,
        showTranslating: Bool,
        footer: String?
    ) -> some View {
        let isFocused = focusedField == key
        let hasContent = !value.wrappedValue.isEmpty

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(label.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.8)
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .fill(Color.primary.opacity(0.5))
                        .frame(width: 22, height: 1)
                }
                Spacer()
                trailingAdornment(
                    isSpeakable: isSpeakable,
                    hasContent: hasContent,
                    showTranslating: showTranslating,
                    text: value.wrappedValue,
                    language: language
                )
            }
            .padding(.bottom, 18)

            TextField("", text: value, axis: .vertical)
                .focused($focusedField, equals: key)
                .font(.system(size: 26, weight: .regular, design: .serif))
                .italic(isMuted)
                .foregroundStyle(isMuted ? AnyShapeStyle(Color.secondary) : AnyShapeStyle(Color.primary))
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .submitLabel(key == .source ? .next : .done)
                .onSubmit {
                    focusedField = (key == .source) ? .target : nil
                }

            if let footer {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                    Text(footer)
                        .font(.system(size: 12, weight: .regular, design: .serif))
                        .italic()
                }
                .foregroundStyle(Color(hue: 0.0, saturation: 0.75, brightness: 0.85))
                .padding(.top, 14)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isFocused ? Color.accentColor.opacity(0.55) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .animation(.easeInOut(duration: 0.18), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: showTranslating)
        .animation(.easeInOut(duration: 0.2), value: hasContent)
        .animation(.easeInOut(duration: 0.2), value: footer)
    }

    // MARK: - Trailing adornment (speaker / translating)

    @ViewBuilder
    private func trailingAdornment(
        isSpeakable: Bool,
        hasContent: Bool,
        showTranslating: Bool,
        text: String,
        language: Language
    ) -> some View {
        if showTranslating {
            HStack(spacing: 6) {
                ProgressView().controlSize(.mini)
                Text("TRANSLATING")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)
            }
            .transition(.opacity)
        } else if isSpeakable && hasContent {
            // Lazy by construction: the speaker (and its underlying
            // AVSpeechSynthesizer static) are only mounted once the field
            // holds content the user could meaningfully hear.
            HStack(spacing: 8) {
                Text("LISTEN")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(.tertiary)
                SpeakerButton(text: text, language: language, player: ttsPlayer) {
                    // play count not tracked outside study sessions
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    // MARK: - Action bar

    private var actionBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color(.systemGroupedBackground).opacity(0), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)
            .allowsHitTesting(false)

            Button {
                saveCard()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: mode.primaryActionIcon)
                    Text(mode.primaryActionTitle)
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isValid ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.secondary.opacity(0.35)))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
            }
            .disabled(!isValid)
            .padding(.bottom, 12)
            .background(Color(.systemGroupedBackground))
            .animation(.easeInOut(duration: 0.18), value: isValid)
        }
    }

    // MARK: - Logic

    private var isTargetMuted: Bool {
        !targetValueIsUserModified && !targetValue.isEmpty
    }

    private var isValid: Bool {
        !sourceValue.isEmpty && !targetValue.isEmpty && !isTranslating
    }

    private func triggerTranslation() {
        guard !targetValueIsUserModified,
              !sourceValue.isEmpty,
              !isTranslating,
              let service = translationService else { return }

        isTranslating = true
        translationFailed = false

        Task {
            do {
                let result = try await service.translate(
                    sourceValue,
                    from: deck.sourceLanguage,
                    to: deck.targetLanguage
                )
                guard !targetValueIsUserModified else {
                    isTranslating = false
                    return
                }
                targetValue = result
                targetValueIsUserModified = false
            } catch {
                translationFailed = true
            }
            isTranslating = false
        }
    }

    private func saveCard() {
        let repo = CardRepository(database: database)
        switch mode {
        case .create:
            guard let deckId = deck.id else { return }
            var card = Card(
                deckId: deckId,
                sourceValue: sourceValue,
                targetValue: targetValue,
                targetValueIsUserModified: targetValueIsUserModified
            )
            try? repo.insert(&card)
            enqueueTTS(forCardId: card.id, previous: nil)
        case .edit(let existing):
            var updated = existing
            updated.sourceValue = sourceValue
            updated.targetValue = targetValue
            updated.targetValueIsUserModified = targetValueIsUserModified
            try? repo.update(&updated)
            enqueueTTS(forCardId: existing.id, previous: existing)
        }
        dismiss()
    }

    /// Enqueue TTS for any speakable field whose text just landed in the Library
    /// (or changed in an edit). New cards always enqueue both speakable sides;
    /// edits skip sides whose text didn't change.
    private func enqueueTTS(forCardId cardId: Int64?, previous: Card?) {
        guard let queue = ttsQueue, let cardId else { return }

        if deck.sourceSpeakable, previous?.sourceValue != sourceValue {
            try? queue.enqueue(
                cardId: cardId,
                fieldSide: .source,
                text: sourceValue,
                language: deck.sourceLanguage
            )
        }
        if deck.targetSpeakable, previous?.targetValue != targetValue {
            try? queue.enqueue(
                cardId: cardId,
                fieldSide: .target,
                text: targetValue,
                language: deck.targetLanguage
            )
        }
        Task.detached(priority: .utility) {
            try? await queue.processPending()
        }
    }
}
