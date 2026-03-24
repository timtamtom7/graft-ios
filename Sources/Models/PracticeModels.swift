import Foundation
import SQLite

// MARK: - PracticePlan

struct PracticePlan: Identifiable, Equatable {
    var id: Int64?
    var skillId: Int64
    var skillName: String
    var skillEmoji: String
    var scheduledAt: Date
    var durationMinutes: Int
    var isCompleted: Bool
    var createdAt: Date

    init(id: Int64? = nil, skillId: Int64, skillName: String, skillEmoji: String, scheduledAt: Date, durationMinutes: Int = 30, isCompleted: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.skillId = skillId
        self.skillName = skillName
        self.skillEmoji = skillEmoji
        self.scheduledAt = scheduledAt
        self.durationMinutes = durationMinutes
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

// MARK: - SkillTimerPreset

struct SkillTimerPreset: Identifiable, Equatable {
    var id: Int64?
    var skillId: Int64
    var durationMinutes: Int
    var label: String
    var createdAt: Date

    init(id: Int64? = nil, skillId: Int64, durationMinutes: Int, label: String = "", createdAt: Date = Date()) {
        self.id = id
        self.skillId = skillId
        self.durationMinutes = durationMinutes
        self.label = label.isEmpty ? "\(durationMinutes)m" : label
        self.createdAt = createdAt
    }

    static let defaults: [Int] = [15, 25, 45, 60, 90]
}

// MARK: - UserGoal

struct UserGoal: Identifiable, Equatable {
    var id: Int64?
    var type: GoalType
    var targetMinutes: Int
    var currentMinutes: Int
    var periodStart: Date
    var periodEnd: Date
    var createdAt: Date

    enum GoalType: String, CaseIterable {
        case weekly = "weekly"
        case monthly = "monthly"

        var displayName: String {
            switch self {
            case .weekly: return "This Week"
            case .monthly: return "This Month"
            }
        }
    }

    init(id: Int64? = nil, type: GoalType, targetMinutes: Int, currentMinutes: Int = 0, periodStart: Date = Date(), periodEnd: Date, createdAt: Date = Date()) {
        self.id = id
        self.type = type
        self.targetMinutes = targetMinutes
        self.currentMinutes = currentMinutes
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.createdAt = createdAt
    }

    var progress: Double {
        guard targetMinutes > 0 else { return 0 }
        return min(Double(currentMinutes) / Double(targetMinutes), 1.0)
    }
}

// MARK: - PersonalRecord

struct PersonalRecord: Equatable {
    var longestSessionMinutes: Int
    var bestFeelRating: Int
    var mostConsistentWeekMinutes: Int
    var totalLifetimeMinutes: Int
    var longestStreakDays: Int

    static var empty: PersonalRecord {
        PersonalRecord(longestSessionMinutes: 0, bestFeelRating: 0, mostConsistentWeekMinutes: 0, totalLifetimeMinutes: 0, longestStreakDays: 0)
    }
}

// MARK: - SkillComparisonData

struct SkillComparisonData: Identifiable {
    let id: Int64
    let name: String
    let emoji: String
    let totalMinutes: Int
    let sessionCount: Int
    let avgFeelRating: Double

    var formattedTime: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}
