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

**Direction**:
Which Field is shown as the prompt and which is revealed as the answer during a Study Session. Set per session, not fixed on the Deck.

**Rating**:
The user's post-recall feedback on a Card: Again / Hard / Good / Easy. Feeds directly into the FSRS scheduler.

**Study Mode**:
The sensory mode chosen at session start: Reading (text only, manual TTS tap), Listening with Text (TTS auto-plays, text visible), or Listening without Text (TTS auto-plays, text hidden). Saved as part of each Review Event.

**Review Event**:
An immutable record of a single card review within a Study Session. Contains: Card ID, Rating, Study Mode, Direction, audio replay count, playback speed used, time-to-reveal (seconds before tapping to show answer), and timestamp. Never edited — only appended. Feeds FSRS scheduling and future per-user weight optimisation.

### Sync and infrastructure

**Sync Backend**:
PocketBase instance hosted on a Hetzner CX22 VPS (~€4/month). Handles user authentication and data sync between devices. Each device holds a local SQLite store; changes sync via PocketBase REST API when online.

**Local Store**:
A SQLite database on each device. The authoritative source for offline study. Syncs to the Sync Backend when connectivity is available.

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
A cumulative count of Cards the user has reviewed and rated Good or Easy at least once. Never decreases. The primary long-term progress signal shown on the home screen.
_Avoid_: retention rate, overdue count, mastery percentage (all read as failure metrics)

**Daily Card Limit**:
The maximum number of new Cards introduced per day. Default: 10. Onboarding ramp: 5/day for the first two weeks, then auto-suggest 10 once the habit is established. Reviews are never capped — capping reviews corrupts FSRS scheduling. Settings screen shows a "projected daily reviews in 30 days" preview when the user adjusts the limit.

### Notifications

**Daily Reminder**:
A single push notification per day at a user-chosen time (picked during onboarding, defaulting to 8 AM or 8 PM). Suppressed entirely if no cards are due. Copy is specific: "You have 12 cards due today. 5 minutes to stay sharp." Never sent before 7 AM or after 10 PM.

**Streak-at-Risk Notification**:
A variant of the Daily Reminder sent when the user has a Streak of 3+ days and has not opened the app within 2 hours of their chosen reminder time. Copy: "[N]-day streak — just 1 card keeps it going." Always accompanied by a Streak Freeze escape valve so it reads as helpful, not coercive.

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
