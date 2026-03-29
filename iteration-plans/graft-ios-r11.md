# Iteration R11 — SQLite Data Integration

## Goal

Replace GraftMac's mock/sample data layer with a real connection to Graft's shared SQLite database via **App Groups**, so the macOS companion shares the same practice data as the iOS app.

## Background

Graft stores all skill and session data in a SQLite database managed by `DatabaseService`. GraftMac currently ships its own mock `MacSkill` and `MacSession` types. This iteration bridges that gap.

## What to Do

### 1. Enable App Groups

- Add App Group capability (`com.graft.app.group`) to both the iOS `Graft` target and the `GraftMac` target.
- Configure a shared container group identifier in Xcode project settings.

### 2. Share the SQLite Database

- The iOS app already uses `DatabaseService` with SQLite.swift. The database file lives in the App Group container.
- GraftMac should open the **same** database file from the shared App Group container instead of its own bundle.
- In `GraftMac/Sources/`, create a `MacDatabaseService.swift` (or adapt `DatabaseService`) that opens the shared DB at:

  ```
  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.graft.app")!
    .appendingPathComponent("graft.sqlite3")
  ```

### 3. Remove Mock Types

- Delete `MacSkill` and `MacSession` from `MacGraftView.swift`.
- Import and use `Skill` and `Session` models from `Sources/Models/` (or move them to a shared module if needed).
- Update all view bindings to use real database-backed types.

### 4. Update GraftMacApp

- Ensure `GraftMacApp.swift` initializes `MacDatabaseService` (or the shared DB) before any view renders.
- Handle the case where the database doesn't exist yet (first launch) — show onboarding or a "No data yet" state gracefully.

### 5. Entitlements

- Update `GraftMac/Resources/GraftMac.entitlements` to include the App Group:

  ```xml
  <key>com.apple.security.application-groups</key>
  <array>
    <string>group.com.graft.app</string>
  </array>
  ```

## Verification

- Build succeeds: `xcodebuild -scheme GraftMac ... build`
- Skills loaded from the shared DB (not hardcoded)
- New sessions written by iOS app appear in GraftMac without rebuilding

## Files to Modify

- `GraftMac/Resources/GraftMac.entitlements` — add App Group
- `GraftMac/Sources/MacGraftView.swift` — remove mock types, use real models
- `GraftMac/Sources/MacDatabaseService.swift` — new file: DB wrapper for macOS
- `GraftMac/Sources/GraftMacApp.swift` — init DB before window appears
- `project.yml` — add App Group capability to GraftMac target

## Files to Create

- `GraftMac/Sources/MacDatabaseService.swift`
