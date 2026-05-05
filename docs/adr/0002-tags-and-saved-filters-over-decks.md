# Use tags and saved filters instead of rigid decks as the primary organisational unit

Cards are organised via a Language field (first-class, required) and free-form Tags, rather than belonging to a single Deck container. A "Saved Filter" — a named AND/OR query over Language and Tags — replaces the Deck as the unit the user studies from.

The core problem with rigid decks: a card can only belong to one deck, forcing duplication when topics overlap (e.g. a Ukrainian word that belongs to both "kitchen" and "everyday food"). Anki's power users already work around this by ignoring decks and using filtered deck queries over tags — this design makes that first-class. Language is a dedicated field rather than a tag to prevent naming inconsistencies ("Ukrainian" vs "UA" vs "ukrainian") and to enable an obvious language-switcher UI affordance.

## Consequences

Tag autocomplete with fuzzy matching and canonical suggestions is required at Card creation time to prevent tag proliferation. An "untagged cards" view must be surfaced prominently. Study session queries must support boolean AND/OR across Language and Tags.
