import Foundation
import UserNotifications
import os.log

/// Manages daily practice reminder notifications
@MainActor
final class ReminderService {
    static let shared = ReminderService()

    private let log = OSLog(subsystem: "com.graft.app", category: "ReminderService")

    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let remindersEnabled = "reminder_enabled"
        static let reminderHour = "reminder_hour"
        static let reminderMinute = "reminder_minute"
        static let reminderSkillId = "reminder_skill_id"
        static let lastReminderDate = "last_reminder_date"
    }

    private init() {}

    // MARK: - Permission

    /// Request notification authorization. Returns true if already authorized or user granted.
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            os_log("Notification authorization: %{public}@", log: log, type: .info, granted ? "granted" : "denied")
            return granted
        } catch {
            os_log("Notification authorization error: %{public}@", log: log, type: .error, error.localizedDescription)
            return false
        }
    }

    /// Check current authorization status
    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Reminder Schedule

    /// Whether reminders are enabled
    var isEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.remindersEnabled) }
        set { userDefaults.set(newValue, forKey: Keys.remindersEnabled) }
    }

    /// Scheduled reminder hour (0-23)
    var reminderHour: Int {
        get { userDefaults.integer(forKey: Keys.reminderHour) }
        set { userDefaults.set(newValue, forKey: Keys.reminderHour) }
    }

    /// Scheduled reminder minute (0-59)
    var reminderMinute: Int {
        get { userDefaults.integer(forKey: Keys.reminderMinute) }
        set { userDefaults.set(newValue, forKey: Keys.reminderMinute) }
    }

    /// Skill ID to reference in reminder (optional)
    var reminderSkillId: Int64? {
        get {
            let val = userDefaults.integer(forKey: Keys.reminderSkillId)
            return val == 0 ? nil : Int64(val)
        }
        set {
            userDefaults.set(newValue.map { Int($0) } ?? 0, forKey: Keys.reminderSkillId)
        }
    }

    /// The scheduled reminder time as a DateComponents
    var reminderTimeComponents: DateComponents {
        DateComponents(hour: reminderHour, minute: reminderMinute)
    }

    /// Formatted reminder time string (e.g. "9:00 AM")
    var formattedReminderTime: String {
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        guard let date = Calendar.current.date(from: components) else {
            return "\(reminderHour):\(String(format: "%02d", reminderMinute))"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    /// Schedule a daily reminder notification at the configured time
    func scheduleReminder(skillName: String, skillEmoji: String) async {
        guard isEnabled else {
            os_log("Reminders disabled, skipping schedule", log: log, type: .info)
            return
        }

        let status = await authorizationStatus()
        guard status == .authorized else {
            os_log("Notifications not authorized (status: %{public}d)", log: log, type: .error, status.rawValue)
            return
        }

        // Cancel any existing reminder first
        await cancelReminder()

        let center = UNUserNotificationCenter.current()

        // Build the content
        let content = UNMutableNotificationContent()
        content.title = "\(skillEmoji) Time to practice \(skillName)"
        content.body = motivationalMessage(for: skillName)
        content.sound = .default
        content.categoryIdentifier = "PRACTICE_REMINDER"

        // Trigger: daily at the set time
        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Use a consistent identifier so we can cancel/update it
        let request = UNNotificationRequest(
            identifier: "com.graft.app.daily-reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            os_log("Scheduled daily reminder for %{public}@ %{public}d:%{public}d",
                   log: log, type: .info,
                   skillName, reminderHour, reminderMinute)
        } catch {
            os_log("Failed to schedule reminder: %{public}@", log: log, type: .error, error.localizedDescription)
        }
    }

    /// Cancel the daily reminder notification
    func cancelReminder() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["com.graft.app.daily-reminder"])
        os_log("Cancelled daily reminder", log: log, type: .info)
    }

    /// Update reminder with new skill info and reschedule
    func updateReminder(skillName: String, skillEmoji: String) async {
        if isEnabled {
            await scheduleReminder(skillName: skillName, skillEmoji: skillEmoji)
        } else {
            await cancelReminder()
        }
    }

    /// Set reminder time and reschedule
    func setReminderTime(hour: Int, minute: Int, skillName: String, skillEmoji: String) async {
        reminderHour = hour
        reminderMinute = minute
        await scheduleReminder(skillName: skillName, skillEmoji: skillEmoji)
    }

    /// Toggle reminders on/off
    func setEnabled(_ enabled: Bool, skillName: String, skillEmoji: String) async {
        isEnabled = enabled
        if enabled {
            await scheduleReminder(skillName: skillName, skillEmoji: skillEmoji)
        } else {
            await cancelReminder()
        }
    }

    // MARK: - AI-Suggested Reminder Time

    /// Get the AI-suggested reminder time from habit insights
    func aiSuggestedTime(for skillId: Int64) -> (hour: Int, minute: Int)? {
        guard let insights = DatabaseService.shared.getHabitAIInsights(for: skillId),
              let timeStr = insights.optimalReminderTime else {
            return nil
        }

        // Parse "9:00 AM" format
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        guard let date = formatter.date(from: timeStr) else { return nil }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return (hour, minute)
    }

    /// Apply AI-suggested reminder time for a skill
    func applyAISuggestedTime(for skillId: Int64, skillName: String, skillEmoji: String) async {
        if let suggested = aiSuggestedTime(for: skillId) {
            await setReminderTime(hour: suggested.hour, minute: suggested.minute, skillName: skillName, skillEmoji: skillEmoji)
            os_log("Applied AI-suggested reminder time: %{public}d:%{public}d",
                   log: log, type: .info, suggested.hour, suggested.minute)
        }
    }

    // MARK: - Motivational Messages

    private func motivationalMessage(for skillName: String) -> String {
        let messages = [
            "Every session counts. Show up for yourself today.",
            "Put in the work — consistency beats intensity.",
            "Your future self will thank you for practicing today.",
            "Small daily improvements lead to stunning results.",
            "The only way to get better is to practice. Simple as that.",
            "Discipline is the bridge between intention and progress.",
            "Today is a new opportunity to grow.",
            "You don't have to be great to start, but you have to start to be great."
        ]
        return messages.randomElement().map { String(format: $0, skillName) } ?? messages[0]
    }
}
