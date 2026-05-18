# Use CloudKit as the sync backend

The app is offline-first with a local SQLite store on each device. CloudKit private database handles sync across the user's Apple devices at no cost. There is no dedicated server, no VPS to manage, and no authentication screen — iCloud identity is implicit.

CloudKit was previously rejected in favour of PocketBase on Hetzner because known future users were not exclusively on Apple devices. That constraint no longer applies: the app is iOS/macOS only by design (see ADR-0004), Android is permanently off the table, and the cost and operational overhead of a dedicated server are not justified for a personal-use app.

## Sync model

Each device maintains a local GRDB/SQLite database as the authoritative offline store. When online, changes sync to CloudKit's private database (scoped per iCloud account). Conflict resolution is handled by CloudKit using server-assigned timestamps — no custom LWW implementation required (see ADR-0005).

## Considered alternatives

- **PocketBase on Hetzner**: Previous choice. €4/month, custom auth, LWW conflict logic to maintain. Eliminated when the decision to go iOS/macOS-only made CloudKit's Apple-only constraint irrelevant.
- **Supabase**: Viable but paid tier starts at $25/month and pauses after 7 days of inactivity on the free tier.
- **No sync (local only)**: Simpler but rules out multi-device use from day one.
