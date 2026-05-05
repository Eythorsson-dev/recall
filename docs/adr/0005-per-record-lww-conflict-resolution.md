# Use per-record last-write-wins for sync conflict resolution

Conflicts between devices are resolved using last-write-wins at the record level. Each Card carries an `updated_at` timestamp (client-assigned) and a `version` integer. On sync, the record with the higher `updated_at` wins. Soft deletes (`deleted_at`) ensure deletions propagate correctly before all devices have synced.

Per-field LWW was considered and rejected as over-engineering for this use case. A true conflict requires the user to edit the same card on two devices while both are offline simultaneously — a rare scenario for a personal app. Even when it occurs, the consequence is losing one small edit on one card, which the user can trivially fix. The added complexity of per-field timestamps is not justified by this risk profile.

CRDTs and Operational Transformation were rejected entirely — both are designed for multi-user collaborative text editing, which is not this app's use case.
