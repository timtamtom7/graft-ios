# Iteration R13 — Practice Reminders & Streak Notifications

## Goal

Add **macOS Notification Center reminders** so GraftMac can push practice reminders and celebrate streak milestones — directly from the macOS companion app.

## Background

Graft has a `ReminderService` for iOS. This iteration brings a similar reminder system to macOS using `UNUserNotificationCenter`, with support for:
1. Daily/recurring practice reminders
2. Streak milestone celebrations
3. "You haven't practiced today" nudges

## What to Do

### 1. Notification Authorization

- On first launch (or from Settings), request notification authorization via `UNUserNotificationCenter`.
- Store the user's preference in `UserDefaults` (or the shared App Group) so it persists across launches.

### 2. ReminderService for macOS

- Create `MacReminderService.swift` mirroring `ReminderService` patterns.
- Key methods:
  - `requestAuthorization()` — request notification permissions
  - `scheduleDailyReminder(at hour: Int, minute: Int)` — daily practice reminder
  - `scheduleStreakCelebration(streak: Int)` — one-time notification for milestone streaks (5, 10, 30, 60, 100 days…)
  - `cancelAllReminders()` — reset
  - `cancelDailyReminder()`

### 3. Daily Reminder Scheduling

- Allow users to set a preferred practice reminder time from the **Settings** view in GraftMac.
- Use `UNCalendarNotificationTrigger` with a repeating trigger (same time every day).
- Notification content:
  - **Title:** "Time to practice! 🎹" (use primary skill emoji)
  - **Body:** "You're on a X-day streak. Keep it going!"
  - **Sound:** default

### 4. Streak Milestone Notifications

- When GraftMac loads and detects a new streak milestone (5, 10, 25, 50, 100, 200, 365 days), fire a `UNNotification` immediately.
- Title: "🔥 Milestone: X-Day Streak!"
- Body: "Amazing dedication. You've practiced X days in a row."

### 5. "Haven't practiced today" Nudge

- On app launch, query today's sessions in the shared DB.
- If zero sessions logged and current time > user's reminder time, show a non-interrupting in-app banner (not a push notification) offering a quick "Log Session" shortcut.

### 6. Settings UI

- Add to `MacGraftView` Settings section:
  - Toggle: "Daily Practice Reminders" (on/off)
  - Time Picker: reminder time
  - Toggle: "Streak Milestone Celebrations" (on/off)
- Persist settings in `UserDefaults` (suite: App Group) so they're shared with iOS.

### 7. Notification Categories & Actions (Optional Enhancement)

- Add notification action: "Log Now" → deep-links to the skill detail log session sheet.
- Configure `UNNotificationCategory` with `identifier: "PRACTICE_REMINDER"`.

## Verification

- Build succeeds
- Notification permission requested on first reminder enable
- Daily reminder fires at the configured time (test by setting time to near-future)
- Streak milestone notification fires for next milestone
- Settings toggle correctly cancels/reschedules reminders

## Files to Create/Modify

- `GraftMac/Sources/MacReminderService.swift` — new file: notification scheduling logic
- `GraftMac/Sources/MacGraftView.swift` — add Settings reminder UI controls
- `GraftMac/Resources/GraftMac.entitlements` — confirm App Group present (for shared UserDefaults)

## Notes

- macOS requires the app to be signed and the user to have granted notification permissions.
- Use `userNotifications` framework (`import UserNotifications`).
- Reminders should not fire if a session was already logged today (check DB before delivering the daily nudge).
- Consider `BGTaskScheduler` for background refresh if notification needs to fire even when app is not running (macOS limitation: background tasks are more restricted than iOS).
