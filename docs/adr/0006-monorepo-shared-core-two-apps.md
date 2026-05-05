# Monorepo with shared core package and two separate app projects

The codebase is structured as a Flutter monorepo with three top-level members:

- `packages/core` — shared business logic: data models, repositories, FSRS scheduler, PocketBase sync client, AI service clients
- `apps/mobile` — Flutter app for iOS and Android, imports core, study-first UI
- `apps/desktop` — Flutter app for macOS and Windows, imports core, creation-focused UI

Each app has its own pubspec.yaml referencing core via a local path dependency. Two separate release pipelines (App Store for mobile, direct distribution or separate store for desktop).

A single adaptive app was rejected because mobile and desktop have meaningfully different primary use cases — study vs creation. Conditional layout logic scattered across a single app would become hard to maintain as the two surfaces diverge. Separating presentation layers eliminates that risk with minimal extra setup cost. The shared core ensures business logic is never duplicated.
