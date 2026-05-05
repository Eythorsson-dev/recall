# Use Flutter with Drift as the cross-platform app framework

Flutter with the Drift ORM is the app framework for all clients (iOS, macOS, Android, Windows). A single Dart codebase targets all four platforms with no UI rewrite required when expanding beyond the initial iOS + macOS launch.

## Decision

Flutter was chosen after researching four options:

- **React Native**: Ruled out. macOS is a day-one launch target and React Native treats it as second-class — `expo-sqlite` doesn't work on macOS, EAS Build doesn't support macOS targets, and every third-party library requires manual macOS compatibility auditing.
- **Tauri v2**: Ruled out for a mobile-first app. No official TTS plugin (requires custom Rust/Swift native bridge), convoluted iOS build pipeline, and WebView-based rendering is noticeable in a swipe-heavy flashcard UI.
- **Swift/SwiftUI + Skip**: Compelling for native Apple quality. Skip (open-sourced Jan 2026) transpiles SwiftUI to Jetpack Compose and is production-viable for standard UI components. Ruled out because Windows is a non-starter from Swift in any realistic timeframe, and Skip introduces framework dependency risk for Android.
- **Flutter**: Production-ready on iOS, macOS, Android, and Windows today. Drift provides the strongest offline-first SQLite story of any cross-platform framework (bundled SQLite, type-safe ORM, identical behaviour across all targets). `flutter_tts` covers TTS on all four platforms natively.

## Trade-offs accepted

Flutter renders its own widgets via the Impeller engine rather than native UIKit/AppKit controls. The app will not feel 100% native to power macOS users. This is acceptable for a flashcard and forms app where the design is fully controlled.
