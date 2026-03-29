# Iteration R12 — macOS Widgets

## Goal

Add **WidgetKit widgets** to GraftMac, allowing users to view their current streak and weekly practice summary directly from the macOS Notification Center.

## Background

Graft already has a `GraftWidgetExtension` for iOS widgets. This iteration ports a similar (or shared) widget experience to macOS using WidgetKit on macOS 15+.

## What to Do

### 1. Add a macOS Widget Extension Target

- Add a new target `GraftMacWidget` (type: `app-extension`, platform: `macOS`) in `project.yml`.
- Use WidgetKit (`import WidgetKit`) and SwiftUI for the widget UI.
- Configure the extension to share the App Group (from R11) so it can read practice data.

### 2. Widget Families

Start with **systemSmall** and **systemMedium**:

| Family | Content |
|--------|---------|
| `systemSmall` | Current streak (days), skill emoji, weekly minutes |
| `systemMedium` | Streak + weekly total + today's practice status |

### 3. Timeline Provider

- `GraftMacWidgetProvider`: conforms to `TimelineProvider`.
- `getSnapshot`: return current skill + session data for preview.
- `getTimeline`: query the shared SQLite DB (App Group) for the current week's practice minutes and streak.
- Refresh policy: `.atEnd` — refresh after the next day boundary.

### 4. Widget UI

- Use `WidgetBackground` and standard Widget colors.
- Display: streak flame emoji 🔥, weekly minutes, day-of-week dots (●●○●●○○ pattern).
- Support dark/light mode via `Color(.white)` / `Color(.black)` or semantic colors.

### 5. Widget Configuration

- No user-configurable parameters in v1 — use the primary (first) skill as the widget subject.
- Optionally: support `IntentTimelineProvider` for skill selection in a future iteration.

### 6. Main App Bundle Inclusion

- The widget extension must be embedded in the GraftMac `.app` bundle.
- Ensure `LD_RUNPATH_SEARCH_PATHS` includes `$(inherited) @executable_path/../Frameworks`.

## Verification

- Build: `xcodebuild -scheme GraftMacWidgetExtension ... build` (if separate scheme) or through main app build
- Widget appears in Notification Center → Edit Widgets → GraftMac
- Widget displays current streak and weekly minutes from shared DB

## Files to Create/Modify

- `GraftMacWidget/` — new extension directory
  - `GraftMacWidget.swift` — main widget bundle entry point
  - `GraftMacWidgetProvider.swift` — timeline provider
  - `GraftMacWidgetViews.swift` — SwiftUI views for small/medium
  - `Info.plist` — extension configuration
  - `GraftMacWidget.entitlements` — App Group entitlement
- `project.yml` — add `GraftMacWidget` target and dependency

## Notes

- macOS WidgetKit requires the widget extension to be codesigned with the same team as the main app.
- macOS 15+ is required for WidgetKit on macOS.
- Consider sharing widget view code between iOS `GraftWidgetExtension` and `GraftMacWidget` where possible to avoid duplication.
