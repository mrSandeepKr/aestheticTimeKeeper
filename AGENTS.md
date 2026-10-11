# AGENTS.md

iOS flip-clock timer app. Xcode project (no workspace), Swift 6 language mode,
iOS 26.5 deployment target, Xcode 26.5. README's iOS 13 / Xcode 12 claims are stale.

## Working style

- Use subagents (explore/task) for searching, reading, and verification whenever possible.
- Keep output extremely compact unless instructed otherwise.

## Structure

- `Aesthetic Time Keeper/` — app target (scheme: `Aesthetic Time Keeper`)
  - `ClockFlip/` — flip-clock UI (ClockFlipView, control buttons, settings)
  - `LiveActivityManager.swift` — all ActivityKit calls funnel through one `SerialTaskQueue`
- `TimeKeeperWidgets/` — widget + Live Activity extension (scheme: `TimeKeeperWidgetsExtension`)
- `SharedUI/`, `Storage/` — **local** Swift packages (iOS+macOS 26), wired via XCLocalSwiftPackageReference
- `TimerWidgetExtension/` — orphaned directory, NOT referenced by the project; do not edit

## Persistence & data sharing

- SwiftData models live in `Storage` (`AppState`, `RunningTimer`, `TimerSetting`).
- Timer control logic lives in `AppState+Extension.swift` deliberately so app and
  extensions share ONE persistence-rule implementation — extend it there, not in callers.
- App and widget share App Group `group.com.sandeepKr.practice.Aesthetic-Time-Keeper`
  (both entitlements files must stay in sync).

## Commands

- Build app: `xcodebuild -project "Aesthetic Time Keeper.xcodeproj" -scheme "Aesthetic Time Keeper" -destination 'generic/platform=iOS Simulator' build`
- Build widget: same with `-scheme TimeKeeperWidgetsExtension`
- Tests exist only in Storage; run: `swift test` (from `Storage/`) — macOS-supported package, no simulator needed
- Storage is a plain SPM package: `swift build` in `Storage/` gives a fast syntax/type check without Xcode

## Conventions

- Swift 6 strict concurrency: shared state must be `@MainActor` or `Sendable`; the compiler enforces this, don't paper over it with `nonisolated(unsafe)`.
