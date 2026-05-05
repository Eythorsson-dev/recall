# Use FSRS as the spaced repetition algorithm

We chose FSRS (Free Spaced Repetition Scheduler) over SM-2, Duolingo HLR, and SuperMemo SM-17/18. FSRS requires 20–30% fewer reviews than SM-2 for the same retention rate, eliminates SM-2's "ease hell" (cards locked into short intervals by a degraded ease factor), and supports targeting a specific retention rate (e.g. 90%). It natively uses the four-rating system (Again/Hard/Good/Easy) the app is built around. The `fsrs` Dart package (`open-spaced-repetition/dart-fsrs` on pub.dev) provides the official MIT-licensed implementation for Flutter. Duolingo HLR requires population-scale training data (cold-start problem); SM-17/18 are closed source; Leitner doesn't fit a four-rating system.

## Data stored per card

`stability: f32`, `difficulty: f32`, `due: DateTime`, `last_review: DateTime`, `state: enum (New | Learning | Review | Relearning)`

The app ships with pre-trained global weights. Per-user weight optimization is deferred until users accumulate sufficient review history (~400+ reviews).
