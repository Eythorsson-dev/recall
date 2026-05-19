# Per-direction FSRS scheduling via CardProgress

Forward (sourceToTarget) and backward (targetToSource) recall are cognitively independent memory traces. Cognitive science research shows practicing one direction does not reliably transfer to the other; both require independent spaced repetition. Every major SRS app (Anki, Mochi, RemNote) treats each direction as a separately scheduled unit.

## Decision

Introduce a `cardProgress` table with one row per `(card, direction)` pair. Each row holds the full FSRS state: stability, difficulty, due, reps, lapses, fsrsState, elapsedDays, scheduledDays, lastReview, learningSteps. All FSRS fields are removed from the `card` table, which becomes a pure content record.

**Two rows are created eagerly when a card is inserted**, both in New state.

**Sibling suppression via queue-time deduplication:** when building a session queue, if both directions of the same card are due, only the more overdue one is included. Tiebreaker: prefer `sourceToTarget` unless the session filter is explicitly `targetToSource`.

**`StudyDirection` has exactly two cases** (`sourceToTarget`, `targetToSource`). The former `.both` case is removed — "both directions" is expressed as a nil direction filter on the session, not a third direction value.

**Words Learned** counts only cards where *both* directions have been rated Good or Easy at least once.

## Migration

Existing FSRS data from each `card` row is copied into both the `sourceToTarget` and `targetToSource` CardProgress rows. Both directions start from the same accumulated state so users see no disruption to their existing schedule.

## Alternatives considered

**Single FSRS score per card (status quo):** does not capture that forward and backward are independent skills. A card where the user knows sourceToTarget well but struggles with targetToSource is scheduled as if both are equally known.

**Reset both directions to New on migration:** discards user review history entirely. Rejected — users would see all previously-studied cards resurface as new, which is punishing and inaccurate.

**Copy existing data to sourceToTarget only, reset targetToSource to New:** more honest about attribution (existing reviews were of unknown direction), but creates an abrupt user-visible gap — all reverse directions appear as brand-new cards. Rejected in favour of the clean cutover.

**Persisted `buriedUntil` for sibling suppression (Anki model):** adds a column and handles multiple sessions per day more precisely. Rejected as over-engineering for the current scale; queue-time deduplication is simpler and sufficient.
