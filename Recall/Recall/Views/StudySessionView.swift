import SwiftUI
import Core

struct StudySessionView: View {
    let database: DatabaseManager
    let deckLookup: [Int64: Deck]
    let selectedDeckIds: [Int64]
    let direction: StudyDirection
    @Environment(\.dismiss) private var dismiss

    @State private var queue: [Card] = []
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var revealTime: Date?
    @State private var sessionComplete = false

    private let scheduler = StudyScheduler()

    var body: some View {
        Group {
            if sessionComplete {
                sessionCompleteView
            } else if let card = currentCard {
                cardView(card)
            } else {
                ProgressView("Loading cards…")
            }
        }
        .navigationTitle("Study (\(currentIndex + 1)/\(queue.count))")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!sessionComplete)
        .onAppear { loadQueue() }
    }

    private var currentCard: Card? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    @ViewBuilder
    private func cardView(_ card: Card) -> some View {
        VStack(spacing: 24) {
            Spacer()

            promptView(card)

            if isRevealed {
                Divider().padding(.horizontal, 32)
                answerView(card)
            }

            Spacer()

            if isRevealed {
                ratingButtons(card)
            } else {
                Button {
                    revealTime = Date()
                    isRevealed = true
                } label: {
                    Text("Show Answer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
    }

    @ViewBuilder
    private func promptView(_ card: Card) -> some View {
        let (label, value) = promptContent(card)
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.largeTitle)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func answerView(_ card: Card) -> some View {
        let (label, value) = answerContent(card)
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }

    private func promptContent(_ card: Card) -> (String, String) {
        let deck = deckLookup[card.deckId]
        switch effectiveDirection(card) {
        case .sourceToTarget:
            return (deck?.sourceField ?? "", card.sourceValue)
        case .targetToSource:
            return (deck?.targetField ?? "", card.targetValue)
        case .both:
            return (deck?.sourceField ?? "", card.sourceValue)
        }
    }

    private func answerContent(_ card: Card) -> (String, String) {
        let deck = deckLookup[card.deckId]
        switch effectiveDirection(card) {
        case .sourceToTarget:
            return (deck?.targetField ?? "", card.targetValue)
        case .targetToSource:
            return (deck?.sourceField ?? "", card.sourceValue)
        case .both:
            return (deck?.targetField ?? "", card.targetValue)
        }
    }

    private func effectiveDirection(_ card: Card) -> StudyDirection {
        if direction == .both {
            return card.id.map { $0 % 2 == 0 ? .sourceToTarget : .targetToSource } ?? .sourceToTarget
        }
        return direction
    }

    @ViewBuilder
    private func ratingButtons(_ card: Card) -> some View {
        HStack(spacing: 12) {
            ratingButton("Again", rating: .again, color: .red, card: card)
            ratingButton("Hard", rating: .hard, color: .orange, card: card)
            ratingButton("Good", rating: .good, color: .green, card: card)
            ratingButton("Easy", rating: .easy, color: .blue, card: card)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func ratingButton(_ title: String, rating: Rating, color: Color, card: Card) -> some View {
        Button {
            rateCard(card, rating: rating)
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func rateCard(_ card: Card, rating: Rating) {
        guard let cardId = card.id else { return }
        let now = Date()
        let timeToReveal = revealTime.map { now.timeIntervalSince($0) } ?? 0

        do {
            var updated = scheduler.schedule(card: card, rating: rating, now: now)
            let cardRepo = CardRepository(database: database)
            try cardRepo.update(&updated)
            queue[currentIndex] = updated

            let eventRepo = ReviewEventRepository(database: database)
            var event = ReviewEvent(
                cardId: cardId,
                rating: Int(rating.rawValue),
                studyMode: "reading",
                direction: direction,
                timeToRevealSeconds: timeToReveal
            )
            try eventRepo.insert(&event)
        } catch {
            print("Study session error: \(error)")
        }

        advanceToNext()
    }

    private func advanceToNext() {
        isRevealed = false
        revealTime = nil
        if currentIndex + 1 < queue.count {
            currentIndex += 1
        } else {
            sessionComplete = true
        }
    }

    private var sessionCompleteView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Session Complete")
                .font(.title)
            Text("You reviewed \(queue.count) card\(queue.count == 1 ? "" : "s").")
                .foregroundStyle(.secondary)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func loadQueue() {
        let repo = CardRepository(database: database)
        let due = (try? repo.fetchDue(deckIds: selectedDeckIds)) ?? []
        queue = due.isEmpty ? ((try? repo.fetchAll(deckIds: selectedDeckIds)) ?? []) : due
        if queue.isEmpty {
            sessionComplete = true
        }
    }

    private func restartSession() {
        currentIndex = 0
        isRevealed = false
        revealTime = nil
        sessionComplete = false
        loadQueue()
    }
}
