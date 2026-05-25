import SwiftUI
import Core

private extension CardProgress {
    enum FSRSState: Int {
        case new = 0, learning = 1, review = 2, relearning = 3

        var label: String {
            switch self {
            case .new: return "New"
            case .learning: return "Learning"
            case .review: return "Review"
            case .relearning: return "Relearning"
            }
        }

        var color: Color {
            switch self {
            case .new: return .blue
            case .learning: return Color(hue: 0.08, saturation: 0.9, brightness: 0.95)
            case .review: return Color(hue: 0.38, saturation: 0.75, brightness: 0.65)
            case .relearning: return Color(hue: 0.0, saturation: 0.8, brightness: 0.8)
            }
        }
    }

    var state: FSRSState { FSRSState(rawValue: fsrsState) ?? .new }

    var humanDue: String {
        let calendar = Calendar.current
        let now = Date()
        if due <= now { return "now" }
        let comps = calendar.dateComponents([.day, .hour, .minute], from: now, to: due)
        let days = comps.day ?? 0
        let hours = comps.hour ?? 0
        let minutes = comps.minute ?? 0
        if days >= 30 {
            let months = days / 30
            return "\(months)mo"
        }
        if days >= 1 { return "\(days)d" }
        if hours >= 1 { return "\(hours)h" }
        if minutes >= 1 { return "\(minutes)m" }
        return "soon"
    }

    var humanStability: (value: String, unit: String) {
        let days = stability
        if days < 1 {
            let hours = max(1, Int((days * 24).rounded()))
            return ("\(hours)", hours == 1 ? "hour" : "hours")
        }
        if days < 30 {
            let whole = Int(days.rounded())
            return ("\(whole)", whole == 1 ? "day" : "days")
        }
        if days < 365 {
            let months = Int((days / 30).rounded())
            return ("\(months)", months == 1 ? "month" : "months")
        }
        let years = days / 365
        let formatted = years < 10 ? String(format: "%.1f", years) : "\(Int(years.rounded()))"
        return (formatted, years < 2 ? "year" : "years")
    }
}

struct CardStatsView: View {
    let database: DatabaseManager
    let deck: Deck
    let card: Card
    let translationService: TranslationService?
    let ttsQueue: TTSGenerationQueue?
    let ttsPlayer: TTSPlayer

    @Environment(\.dismiss) private var dismiss
    @State private var progressByDirection: [StudyDirection: CardProgress] = [:]
    @State private var events: [ReviewEvent] = []
    @State private var showingEdit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    directionPanels
                    historySection
                }
                .padding(.bottom, 48)
            }
            .background(Color(.systemGroupedBackground))
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
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showingEdit = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            CardEditView(
                database: database,
                deck: deck,
                translationService: translationService,
                ttsQueue: ttsQueue,
                ttsPlayer: ttsPlayer,
                card: card
            )
            .onDisappear { load() }
        }
        .onAppear { load() }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(deck.sourceField.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.0)
                .foregroundStyle(.secondary)

            Rectangle()
                .fill(Color.primary.opacity(0.65))
                .frame(width: 28, height: 1)
                .padding(.top, 8)
                .padding(.bottom, 14)

            Text(card.sourceValue)
                .font(.system(size: 40, weight: .regular, design: .serif))
                .foregroundStyle(.primary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Text(deck.targetField.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 24)
            .padding(.bottom, 8)

            Text(card.targetValue)
                .font(.system(size: 24, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, 8)
        .padding(.bottom, 40)
    }

    // MARK: - Direction Panels

    private var directionPanels: some View {
        VStack(spacing: 12) {
            directionPanel(.sourceToTarget)
            directionPanel(.targetToSource)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func directionPanel(_ dir: StudyDirection) -> some View {
        let progress = progressByDirection[dir]
        let state = progress?.state ?? .new
        let promptLang = dir == .sourceToTarget ? deck.sourceField : deck.targetField
        let answerLang = dir == .sourceToTarget ? deck.targetField : deck.sourceField
        let directionLabel = dir == .sourceToTarget ? "Forward" : "Reverse"
        let started = progress != nil && (progress?.reps ?? 0) > 0

        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(directionLabel.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.8)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Text(promptLang)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.tertiary)
                        Text(answerLang)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }
                Spacer()
                Text(state.label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(state.color.opacity(0.14))
                    .foregroundStyle(state.color)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 28)

            // Hero memory stat
            if started, let p = progress {
                let (value, unit) = p.humanStability
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.system(size: 60, weight: .thin, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                    Text(unit)
                        .font(.system(size: 18, weight: .light, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("MEMORY")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(1.4)
                            .foregroundStyle(.tertiary)
                        Text("predicted retention")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.bottom, 22)
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("—")
                        .font(.system(size: 60, weight: .thin, design: .rounded))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("UNSTUDIED")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(1.4)
                            .foregroundStyle(.tertiary)
                        Text("queued for next session")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.bottom, 22)
            }

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 1)

            // Mini stats grid
            HStack(spacing: 0) {
                miniStat(
                    value: "\(progress?.reps ?? 0)",
                    label: "Reviews"
                )
                miniStatDivider()
                miniStat(
                    value: "\(progress?.lapses ?? 0)",
                    label: "Lapses",
                    color: (progress?.lapses ?? 0) > 0 ? Color(hue: 0.0, saturation: 0.7, brightness: 0.8) : nil
                )
                miniStatDivider()
                miniStat(
                    value: progress?.humanDue ?? "—",
                    label: "Next",
                    color: (progress?.due ?? .distantFuture) <= Date() ? Color(hue: 0.08, saturation: 0.9, brightness: 0.95) : nil
                )
            }
            .padding(.top, 14)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func miniStat(value: String, label: String, color: Color? = nil) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(color ?? .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func miniStatDivider() -> some View {
        Rectangle()
            .fill(Color.primary.opacity(0.06))
            .frame(width: 1, height: 32)
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("HISTORY")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2.0)
                    .foregroundStyle(.secondary)
                Spacer()
                if !events.isEmpty {
                    Text("\(events.count) review\(events.count == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 28)

            if events.isEmpty {
                Text("No reviews yet.")
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 28)
            } else {
                ratingTimeline
                eventList
            }
        }
        .padding(.top, 44)
    }

    private var ratingTimeline: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 6) {
                ForEach(events.reversed()) { event in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(ratingColor(event.rating))
                            .frame(width: 9, height: 9)
                        directionGlyph(event.direction)
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private func directionGlyph(_ direction: StudyDirection) -> some View {
        Image(systemName: direction == .sourceToTarget ? "arrow.up" : "arrow.down")
    }

    private var eventList: some View {
        VStack(spacing: 0) {
            ForEach(events.prefix(25)) { event in
                eventRow(event)
            }
        }
        .padding(.horizontal, 20)
    }

    private func eventRow(_ event: ReviewEvent) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(ratingColor(event.rating))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(ratingLabel(event.rating))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(directionRowLabel(event.direction))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Text(absoluteTime(event.timestamp))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(relativeTime(event.timestamp))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1fs to recall", event.timeToRevealSeconds))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(0.05))
                .frame(height: 1)
                .padding(.horizontal, 8)
        }
    }

    // MARK: - Helpers

    private func ratingColor(_ r: Int) -> Color {
        switch r {
        case 1: return Color(hue: 0.0, saturation: 0.75, brightness: 0.85)   // Again — red
        case 2: return Color(hue: 0.08, saturation: 0.9, brightness: 0.95)   // Hard — amber
        case 3: return Color(hue: 0.38, saturation: 0.75, brightness: 0.65)  // Good — green
        case 4: return .blue                                                  // Easy — blue
        default: return .gray
        }
    }

    private func ratingLabel(_ r: Int) -> String {
        switch r {
        case 1: return "Again"
        case 2: return "Hard"
        case 3: return "Good"
        case 4: return "Easy"
        default: return "—"
        }
    }

    private func directionRowLabel(_ dir: StudyDirection) -> String {
        switch dir {
        case .sourceToTarget: return "\(deck.sourceField) → \(deck.targetField)"
        case .targetToSource: return "\(deck.targetField) → \(deck.sourceField)"
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func absoluteTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func load() {
        guard let cardId = card.id else { return }
        let progressRepo = CardProgressRepository(database: database)
        let eventRepo = ReviewEventRepository(database: database)

        if let all = try? progressRepo.fetchAll(forCard: cardId) {
            var lookup: [StudyDirection: CardProgress] = [:]
            for progress in all {
                lookup[progress.direction] = progress
            }
            progressByDirection = lookup
        }

        events = (try? eventRepo.fetchAll(forCard: cardId)) ?? []
    }
}
