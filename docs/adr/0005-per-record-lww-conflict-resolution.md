# CloudKit handles sync conflict resolution

Conflicts between devices are resolved by CloudKit using server-assigned timestamps on the private database. No custom conflict resolution logic is implemented in the app.

The previous approach (per-record last-write-wins via client-assigned `updated_at` + `version` fields) was designed for PocketBase, which required the app to implement conflict detection and resolution explicitly. CloudKit's private database handles this at the infrastructure level — each record has a server-managed `recordChangeTag`; CloudKit rejects stale writes and the app re-fetches and retries.

For a single-user private database, true conflicts (editing the same card on two devices simultaneously while both are offline) are rare. When they occur, CloudKit's server-wins resolution is acceptable — the consequence is losing one small edit on one card, which the user can trivially fix.

Custom CRDT or operational transform logic was not considered — this is not a multi-user collaborative editing use case.
