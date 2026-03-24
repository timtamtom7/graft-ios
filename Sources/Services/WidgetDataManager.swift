import Foundation
import WidgetKit

/// Manages widget data shared between the main app and widget extension
@MainActor
final class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let appGroupId = "group.com.graft.app"
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    private init() {}

    /// Call this after any session is logged or deleted to refresh the widget
    func refreshWidgetData() {
        let skills = DatabaseService.shared.getActiveSkills()
        let calendar = Calendar.current
        let now = Date()

        // Get primary skill
        let primarySkill = skills.first

        // Calculate weekly minutes
        var weeklyTotal = 0
        var overallStreak = 0
        var practicedToday = false

        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now

        if let skill = primarySkill, let skillId = skill.id {
            let sessions = DatabaseService.shared.getWeeklySessions(for: skillId, weekStart: weekStart)
            weeklyTotal = sessions.reduce(0) { $0 + $1.totalMinutes }

            // Streak
            var checkDate = now
            while true {
                let daySessions = DatabaseService.shared.getSessions(for: skillId, on: checkDate)
                if daySessions.isEmpty { break }
                overallStreak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            }

            // Practiced today
            let todaySessions = DatabaseService.shared.getSessions(for: skillId, on: now)
            practicedToday = !todaySessions.isEmpty

            // Update shared defaults
            sharedDefaults?.set(skill.name, forKey: "widget_skill_name")
            sharedDefaults?.set(skill.emoji, forKey: "widget_skill_emoji")
            sharedDefaults?.set(weeklyTotal, forKey: "widget_weekly_minutes")
            sharedDefaults?.set(overallStreak, forKey: "widget_streak_days")
            sharedDefaults?.set(practicedToday, forKey: "widget_practice_today")
        } else if let firstSkill = skills.first {
            // All skills combined
            for skill in skills {
                guard let skillId = skill.id else { continue }
                let sessions = DatabaseService.shared.getWeeklySessions(for: skillId, weekStart: weekStart)
                weeklyTotal += sessions.reduce(0) { $0 + $1.totalMinutes }
            }

            // Overall streak (any skill)
            var checkDate = now
            while true {
                var anySession = false
                for skill in skills {
                    guard let skillId = skill.id else { continue }
                    let daySessions = DatabaseService.shared.getSessions(for: skillId, on: checkDate)
                    if !daySessions.isEmpty { anySession = true; break }
                }
                if !anySession { break }
                overallStreak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            }

            // Practiced today (any skill)
            for skill in skills {
                guard let skillId = skill.id else { continue }
                let todaySessions = DatabaseService.shared.getSessions(for: skillId, on: now)
                if !todaySessions.isEmpty { practicedToday = true; break }
            }

            sharedDefaults?.set("All Skills", forKey: "widget_skill_name")
            sharedDefaults?.set("🎯", forKey: "widget_skill_emoji")
            sharedDefaults?.set(weeklyTotal, forKey: "widget_weekly_minutes")
            sharedDefaults?.set(overallStreak, forKey: "widget_streak_days")
            sharedDefaults?.set(practicedToday, forKey: "widget_practice_today")
        } else {
            // No skills
            sharedDefaults?.set("Practice", forKey: "widget_skill_name")
            sharedDefaults?.set("🎯", forKey: "widget_skill_emoji")
            sharedDefaults?.set(0, forKey: "widget_weekly_minutes")
            sharedDefaults?.set(0, forKey: "widget_streak_days")
            sharedDefaults?.set(false, forKey: "widget_practice_today")
        }

        // Trigger widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "GraftWidget")
    }
}
