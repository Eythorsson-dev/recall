import SwiftUI
import Core

struct StudySessionView: View {
    let database: DatabaseManager
    let deckLookup: [Int64: Deck]
    let selectedDeckIds: [Int64]
    let direction: StudyDirection?
    @Environment(\.dismiss) private var dismiss

    @State private var queue: [CardProgress] = []
    @State private var cardLookup: [Int64: Card] = [:]
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var revealTime: Date?
    @State private var sessionComplete = false

    private let scheduler = StudyScheduler()

    var body: some View {
        Group {
            if sessionComplete {
                sessionCompleteView
            } else if let progress = currentProgress {
                cardView(progress)
            } else {
                ProgressView("Loading cards…")
            }
        }
        .navigationTitle("Study (\(currentIndex + 1)/\(queue.count))")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!sessionComplete)
        .onAppear { loadQueue() }
    }

    private var currentProgress: CardProgress? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    @ViewBuilder
    private func cardView(_ progress: CardProgress) -> some View {
        VStack(spacing: 24) {
            Spacer()

            promptView(progress)

            if isRevealed {
                Divider().padding(.horizontal, 32)
                answerView(progress)
            }

            Spacer()

            if isRevealed {
                ratingButtons(progress)
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
    private func promptView(_ progress: CardProgress) -> some View {
        let (label, value) = promptContent(progress)
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
    private func answerView(_ progress: CardProgress) -> some View {
        let (label, value) = answerContent(progress)
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

    private func promptContent(_ progress: CardProgress) -> (String, String) {
        let card = cardLookup[progress.cardId]
        let deck = card.flatMap { deckLookup[$0.deckId] }
        switch progress.direction {
        case .sourceToTarget:
            return (deck?.sourceField ?? "", card?.sourceValue ?? "")
        case .targetToSource:
            return (deck?.targetField ?? "", card?.targetValue ?? "")
        }
    }

    private func answerContent(_ progress: CardProgress) -> (String, String) {
        let card = cardLookup[progress.cardId]
        let deck = card.flatMap { deckLookup[$0.deckId] }
        switch progress.direction {
        case .sourceToTarget:
            return (deck?.targetField ?? "", card?.targetValue ?? "")
        case .targetToSource:
            return (deck?.sourceField ?? "", card?.sourceValue ?? "")
        }
    }

    @ViewBuilder
    private func ratingButtons(_ progress: CardProgress) -> some View {
        HStack(spacing: 12) {
            ratingButton("Again", rating: .again, color: .red, progress: progress)
            ratingButton("Hard", rating: .hard, color: .orange, progress: progress)
            ratingButton("Good", rating: .good, color: .green, progress: progress)
            ratingButton("Easy", rating: .easy, color: .blue, progress: progress)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func ratingButton(_ title: String, rating: Rating, color: Color, progress: CardProgress) -> some View {
        Button {
            rateCard(progress, rating: rating)
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

    private func rateCard(_ progress: CardProgress, rating: Rating) {
        let now = Date()
        let timeToReveal = revealTime.map { now.timeIntervalSince($0) } ?? 0

        do {
            var updated = scheduler.schedule(progress: progress, rating: rating, now: now)
            let progressRepo = CardProgressRepository(database: database)
            try progressRepo.update(&updated)
            queue[currentIndex] = updated

            let eventRepo = ReviewEventRepository(database: database)
            var event = ReviewEvent(
                cardId: progress.cardId,
                rating: Int(rating.rawValue),
                studyMode: "reading",
                direction: progress.direction,
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
        let progressRepo = CardProgressRepository(database: database)
        let cardRepo = CardRepository(database: database)

        do {
            let due = try progressRepo.fetchDueForSession(
                deckIds: selectedDeckIds,
                direction: direction
            )
            let progressItems = due.isEmpty
                ? try progressRepo.fetchAllForSession(deckIds: selectedDeckIds, direction: direction)
                : due

            queue = progressItems

            let cardIds = Set(progressItems.map(\.cardId))
            var lookup: [Int64: Card] = [:]
            for cardId in cardIds {
                if let card = try cardRepo.fetchById(cardId) {
                    lookup[cardId] = card
                }
            }
            cardLookup = lookup

            if queue.isEmpty { sessionComplete = true }
        } catch {
            print("Load queue error: \(error)")
            sessionComplete = true
        }
    }
}
