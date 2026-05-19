# Recall

A mobile-first, offline-first flashcard application for language learning, inspired by Anki. Users study vocabulary and practice listening through spaced repetition. A companion desktop app handles content creation and sync.

## Language

### Core entities

**Library**:
The user's entire personal store — all their Decks, Cards, and study history.
_Avoid_: Collection

**Deck**:
A named set of Cards studied together. Defines its own field schema and card layout directly — there is no separate reusable Card Type entity.
_Avoid_: Collection, set, package

**Card**:
An individual data record inside a Deck, conforming to the Deck's field schema.
_Avoid_: Note, entry, item

**Field**:
A named data slot on a Card (e.g. "Spanish", "English", "Example Sentence"). Fields are defined on the Deck and may be marked speakable.
_Avoid_: Column, attribute, property

**Flashcard**:
A built-in Deck template with a source language field and a target language field. The fields are named after the languages (e.g. "Spanish", "English"), not "front" and "back".
_Avoid_: Basic card, front/back card

### Study session

**Study Session**:
A single sitting in which the user reviews Cards from a Deck. Direction (source→target, target→source, or both) is chosen at the start of each session.

**Study Direction**:
Which Field is shown as the prompt and which is revealed as the answer. Two values: `sourceToTarget` or `targetToSource`. Used on both `CardProgress` (to identify which memory trace is being scheduled) and as an optional session filter (when nil, cards from both directions are included).
_Avoid_: "both" as a direction value — "both directions" means no direction filter, not a third direction.

**CardProgress**:
The accumulated FSRS scheduling state for a Card in one Study Direction. Holds: stability, difficulty, due, reps, lapses, FSRS state, elapsed days, scheduled days, last review, learning steps. Each Card has exactly two CardProgress records — one per Study Direction. Drives when that direction of the card is next surfaced for review.
_Avoid_: card schedule, card state, FSRS record

**CardProgress Migration**:
When introducing per-direction CardProgress, existing FSRS data from each Card is copied into *both* the `sourceToTarget` and `targetToSource` rows. Both directions start from the same accumulated state. No scheduling history is lost.

**Sibling Suppression**:
When building a session queue, if both directions of the same Card are due, only the more overdue one (earlier `due` date) is included. The other waits for the next session. Tiebreaker when due dates are equal: prefer `sourceToTarget`, unless the session's direction filter is explicitly `targetToSource`, in which case prefer `targetToSource`.

**Rating**:
The user's post-recall feedback on a Card: Again / Hard / Good / Easy. Feeds directly into the FSRS scheduler.

**Study Mode**:
The sensory mode chosen at session start: Reading (text only, manual TTS tap), Listening with Text (TTS auto-plays, text visible), or Listening without Text (TTS auto-plays, text hidden). Saved as part of each Review Event.

- **Reading**: no auto-play. Each speakable Field has a dedicated speaker button the user taps to play.
- **Listening with Text**: prompt field audio auto-plays when the card appears; answer field audio auto-plays 500ms after the answer is revealed. Text visible throughout.
- **Listening without Text**: same auto-play timing as Listening with Text, but text is hidden — the user hears the prompt and must recall the answer before revealing. Text appears on reveal.

In all modes, a speaker button is shown for each speakable Field and can be tapped at any time before rating to replay audio. Each tap (including the initial auto-play) increments `audioPlayCount` on the Review Event.

**Review Event**:
An immutable record of a single card review within a Study Session. Contains: Card ID, Rating, Study Mode, Direction, audio play count, time-to-reveal (seconds before tapping to show answer), and timestamp. Never edited — only appended. Feeds FSRS scheduling and future per-user weight optimisation.
_Note_: `playbackSpeed` is retained and always written as `1.0` in the MVP — preserved for when variable speed is introduced. `audioPlayCount` counts every speaker button tap (including the initial auto-play in Listening modes) — not just replays.

### Sync and infrastructure

**Sync Backend**:
CloudKit private database scoped to the user's iCloud account. Handles data sync between Apple devices at no cost. No dedicated server or authentication screen — iCloud identity is implicit. Each device holds a local SQLite store; changes sync via CloudKit when online.

**Local Store**:
A SQLite database on each device managed via GRDB. The authoritative source for offline study. Syncs to CloudKit when connectivity is available.

### Card creation

**Auto-Translation**:
Automatic population of a target-language Field from a source-language Field using an AI translation service. Fires after a short debounce when the source Field changes. Generated content is rendered visually distinct (muted + AI badge) until confirmed.

**User-Modified Flag**:
A per-Field marker indicating the user has manually edited an auto-generated value. When set, the system never silently overwrites the field — instead it shows a non-blocking inline prompt if the source field changes: "Source changed — [Keep my translation] [Regenerate]".

### Organisation

**Language**:
A first-class field on every Card (e.g. "Ukrainian", "Spanish"). Not a tag. Enables a language switcher in the UI and prevents naming inconsistencies.
_Avoid_: language tag

**Tag**:
A free-form label attached to a Card for cross-cutting categorisation (topic, grammar category, source, difficulty, etc.). A Card may have many Tags. Tags are not hierarchical containers.
_Avoid_: folder, category, deck label

**Saved Filter**:
A named, dynamic query combining a Language and one or more Tags with AND/OR logic (e.g. "Ukrainian Kitchen" = language=Ukrainian AND tag=kitchen). Replaces the rigid Deck as the primary study unit.
_Avoid_: deck, collection, folder

### Progress and motivation

**Streak**:
A count of consecutive days the user has completed their daily session. Requires a built-in Streak Freeze mechanic — a broken streak without forgiveness causes abandonment. Shown prominently on the home screen.

**Streak Freeze**:
A forgiveness token that preserves a Streak when the user misses a day. Required alongside Streak from day one.

**Session Progress**:
A "X of Y cards today" progress bar shown during a Study Session. Gives a clear "done for today" signal and triggers goal-gradient motivation. Y is the Daily Card Limit, not the total due count.

**Words Learned**:
A cumulative count of Cards where *both* Study Directions have been rated Good or Easy at least once. Never decreases. The primary long-term progress signal shown on the home screen. A card with only one direction learned does not count — knowing a word one way is not the same as knowing it.
_Avoid_: retention rate, overdue count, mastery percentage (all read as failure metrics)

**Daily Card Limit**:
The maximum number of new Cards introduced per day. Default: 10. Onboarding ramp: 5/day for the first two weeks, then auto-suggest 10 once the habit is established. Reviews are never capped — capping reviews corrupts FSRS scheduling. Settings screen shows a "projected daily reviews in 30 days" preview when the user adjusts the limit.

### Notifications

**Daily Reminder**:
A single push notification per day at a user-chosen time (picked during onboarding, defaulting to 8 AM or 8 PM). Suppressed entirely if no cards are due. Copy is specific: "You have 12 cards due today. 5 minutes to stay sharp." Never sent before 7 AM or after 10 PM.

**Streak-at-Risk Notification**:
A variant of the Daily Reminder sent when the user has a Streak of 3+ days and has not opened the app within 2 hours of their chosen reminder time. Copy: "[N]-day streak — just 1 card keeps it going." Always accompanied by a Streak Freeze escape valve so it reads as helpful, not coercive.

### TTS and audio

**Supported Language**:
An enum in `Core` representing every language the app provides TTS for. Each case carries a hard-coded `defaultVoiceID` mapping to a specific Google Cloud TTS Neural2 voice. Adding a new language means adding a case — no settings screen or per-user voice selection in the MVP.
_Avoid_: language string, locale string

**TTS Service**:
The `Core` component responsible for generating speech audio from a speakable Field value. Primary engine: Google Cloud TTS Neural2 (free 1M chars/month, high-fidelity, supports Ukrainian and Spanish). Fallback engine: `AVSpeechSynthesizer` — used only when no cached audio exists and the device is offline. The fallback is silent for unsupported languages (e.g. Ukrainian via AVSpeechSynthesizer); the TTS Service never surfaces a broken state to the user.

**Audio Cache**:
Content-addressed storage of generated audio files, keyed by `SHA256(text + language + voiceID)`. Lives in the app's local documents directory and syncs to CloudKit. Deduplicates identical text across Cards — "hola" is generated and stored once regardless of how many Cards contain it. Orphaned files (no Card references the hash) are removed on periodic garbage-collection sweeps.

**TTS Generation Queue**:
A persistent, idempotent queue of pending audio generation jobs. A job is enqueued when a Card enters the Library (on save for manual cards, on accept for AI-generated cards) or when a speakable Field is edited. Jobs execute when connectivity is available and are retried on failure. Survives app restarts. Once a job completes, the resulting audio file is written to the Audio Cache and synced via CloudKit.

**Speakable Field**:
A Field on a Card whose value should be spoken aloud during study. Marked at the Deck level via `sourceSpeakable` / `targetSpeakable`. Only speakable Fields enqueue TTS generation jobs and appear in Listening study modes.
_Avoid_: audio field, voice field

### AI features

**Card Generation**:
AI-driven creation of Cards from a natural-language prompt (e.g. "50 most common Ukrainian words", "kitchen phrases in Spanish"). Generated Cards land in a Generation Review screen before entering the Library.

**Generation Review**:
A scannable list of AI-generated Cards shown after Card Generation completes. Each row shows the source and target field values. "Accept All" is the primary action — review is optional, not mandatory. The user can tap any card to open the full card editor, or long-press to delete it. Cards enter the Library only after acceptance.

**Sentence Builder**:
A separate module that uses AI to generate cloze sentences (fill-in-the-blank) from the user's confirmed known vocabulary. Default mode: one target word blanked per sentence, all other words from the user's known set. Advanced mode: full sentence construction. Sentences are scheduled for review using FSRS alongside individual Cards.

**Cloze**:
The default Sentence Builder interaction — a generated sentence with exactly one target word blanked out. The user fills in the blank from memory.
_Avoid_: gap-fill (use cloze)

**Known Vocabulary**:
The set of Cards a user has reviewed and rated Good or Easy at least once. Used by the Sentence Builder to constrain generation — every word in a generated sentence except the target word must be in the user's Known Vocabulary.

## Relationships

- A **Library** contains many **Cards**; each Card has a **Language** field and zero or more **Tags**
- A **Flashcard** is a built-in Card schema; its Fields are named after the source and target languages
- A **Saved Filter** is a named query over **Language** and **Tags** — it produces a dynamic set of Cards for study
- A **Study Session** draws from a **Saved Filter** and uses a chosen **Direction**
- Each **Card** review within a session produces a **Rating**
- The **Sentence Builder** draws from **Known Vocabulary** to generate **Cloze** sentences, which are also scheduled via FSRS

## Flagged ambiguities

- "Collection" was used to mean both the user's full library and a set of cards — resolved: **Library** for the former, **Saved Filter** for the latter.
- "Front/back" was proposed for Flashcard fields — rejected in favour of language-named Fields (e.g. "Spanish", "English").
- "Deck" was considered as a rigid container — rejected in favour of Tags + Saved Filters to avoid card duplication across overlapping topics.
- "Free construction" was proposed as the primary Sentence Builder mode — downgraded to advanced mode; Cloze is the default based on retention/dropout research.
