# Use PocketBase on Hetzner CX22 as the sync backend

The app is offline-first with a local SQLite store on each device. PocketBase serves as the sync backend — handling user auth, conflict resolution, and data exchange between devices via its REST API. Hosted on a Hetzner CX22 VPS (~€4/month).

PocketBase was chosen over CloudKit (Apple-only, rules out known non-Apple users), Supabase (paid tier starts at $25/month), and PowerSync ($49/month). Hetzner was chosen over Oracle Cloud Free Tier (documented history of accounts terminated without warning, no SLA, no appeals process) and Railway (similar cost but less control). At ~$4-5/month, hosting fits comfortably within the $5-10/month budget.

## Sync model

Each device maintains a local SQLite database. When online, changes sync to PocketBase via its REST API. Offline study is fully functional with no degradation. User accounts are required from day one — this enables the planned small-community expansion to non-Apple users without a sync architecture change.

## Considered alternatives

- **CloudKit**: Free and natively bridges iOS/macOS, but Apple-only. Known future users are not on the Apple ecosystem — ruled out.
- **Oracle Cloud Free Tier**: Nominally free, but multiple documented cases of accounts terminated without warning and no SLA or appeals process. Risk of total data loss with no recourse.
- **Supabase free tier**: Viable for personal use but pauses after 7 days inactivity and jumps to $25/month paid.
- **Raspberry Pi + Cloudflare Tunnel**: Zero cost alternative if hardware is already owned. Acceptable for personal use only — not recommended if other users depend on uptime.
