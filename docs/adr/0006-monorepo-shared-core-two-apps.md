# Swift Package for shared core logic, single Xcode project

The codebase is structured with two top-level members:

- `Core/` — local Swift Package: data models, GRDB repositories, FSRS scheduler, CloudKit sync client, AI service clients. Platform-agnostic — no UIKit or AppKit imports.
- `Recall/` — single Xcode project with an iOS target and a macOS target. The Xcode project declares `Core/` as a local Swift Package dependency. iOS and macOS share SwiftUI views in `Shared/`; platform-specific views live in `iOS/` and `macOS/` respectively.

The macOS target is scaffolded in the Xcode project but its views are deferred until slice 9, alongside CloudKit sync. The iOS target is the focus for slices 1–8.

## Why not two separate Xcode projects

A separate `apps/ios/` and `apps/macos/` project structure would require duplicating the Xcode configuration, two separate release pipelines from day one, and constant discipline to keep shared code in sync. A single project with two targets is the standard Apple approach for this case and keeps overhead minimal while the macOS surface is still skeletal.

## Why not a single adaptive app

Mobile (iOS) and desktop (macOS) have meaningfully different primary use cases — study-first vs creation-first. Conditional layout logic scattered through a single view hierarchy would become hard to maintain as the two surfaces diverge. Separating presentation into `iOS/` and `macOS/` directories with a `Shared/` base eliminates that risk.
