# Use Swift + SwiftUI + GRDB as the app framework

Swift with SwiftUI is the framework for all clients (iOS first; macOS introduced alongside sync in slice 9). GRDB is the SQLite ORM for the local store. A local Swift Package (`Core/`) holds all shared business logic consumed by the Xcode project.

## Decision

Flutter was the previous choice and was rejected after implementation because it renders its own widgets via the Impeller engine rather than native UIKit/AppKit controls. The result does not feel native — scroll physics, haptics, typography rendering, context menus, and accessibility are all slightly off. For a daily-use app on Apple devices, this is unacceptable.

Swift + SwiftUI was previously rejected because of the cross-platform constraint (Android, Windows). That constraint no longer applies — the app is Apple-only by design (see ADR-0003). With that constraint removed, SwiftUI is the correct choice: actual native components, real UIKit scroll physics, SF Symbols, full accessibility tree, and natural CloudKit integration.

## Structure

- `Core/` — local Swift Package: FSRS scheduler (`open-spaced-repetition/swift-fsrs`), GRDB repositories, CloudKit sync client, AI service clients
- `Recall/` — single Xcode project with iOS and macOS targets; macOS deferred until slice 9

## Trade-offs accepted

- iOS and macOS views share SwiftUI code but diverge where platform idioms differ (`#if os(iOS)`, `NavigationSplitView`). This is normal SwiftUI multi-platform development.
- The 7 slices already implemented in Flutter are discarded. The domain logic is well-understood and the rewrite in Swift is estimated to be faster than the original implementation.
- Android and Windows are permanently off the table. This was an explicit decision — see ADR-0003.
