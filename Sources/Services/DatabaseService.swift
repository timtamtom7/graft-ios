import Foundation
import SQLite

@MainActor
final class DatabaseService {
    static let shared = DatabaseService()

    private var db: Connection?

    // Skills table
    private let skills = Table("skills")
    private let skillId = SQLite.Expression<Int64>("id")
    private let skillName = SQLite.Expression<String>("name")
    private let skillEmoji = SQLite.Expression<String>("emoji")
    private let skillIsActive = SQLite.Expression<Bool>("is_active")
    private let skillCreatedAt = SQLite.Expression<Date>("created_at")
    private let skillPriority = SQLite.Expression<Int>("priority")

    // Sessions table
    private let sessions = Table("sessions")
    private let sessionId = SQLite.Expression<Int64>("id")
    private let sessionSkillId = SQLite.Expression<Int64>("skill_id")
    private let sessionDurationMinutes = SQLite.Expression<Int>("duration_minutes")
    private let sessionFeelRating = SQLite.Expression<Int>("feel_rating")
    private let sessionNotes = SQLite.Expression<String?>("notes")
    private let sessionPracticedAt = SQLite.Expression<Date>("practiced_at")
    private let sessionIsTimerBased = SQLite.Expression<Bool>("is_timer_based")

    // Planned sessions table
    private let plannedSessions = Table("planned_sessions")
    private let planId = SQLite.Expression<Int64>("id")
    private let planSkillId = SQLite.Expression<Int64>("skill_id")
    private let planSkillName = SQLite.Expression<String>("skill_name")
    private let planSkillEmoji = SQLite.Expression<String>("skill_emoji")
    private let planScheduledAt = SQLite.Expression<Date>("scheduled_at")
    private let planDurationMinutes = SQLite.Expression<Int>("duration_minutes")
    private let planIsCompleted = SQLite.Expression<Bool>("is_completed")
    private let planCreatedAt = SQLite.Expression<Date>("created_at")

    // Timer presets table
    private let timerPresets = Table("timer_presets")
    private let presetId = SQLite.Expression<Int64>("id")
    private let presetSkillId = SQLite.Expression<Int64>("skill_id")
    private let presetDurationMinutes = SQLite.Expression<Int>("duration_minutes")
    private let presetLabel = SQLite.Expression<String>("label")
    private let presetCreatedAt = SQLite.Expression<Date>("created_at")

    // User goals table
    private let userGoals = Table("user_goals")
    private let goalId = SQLite.Expression<Int64>("id")
    private let goalType = SQLite.Expression<String>("type")
    private let goalTargetMinutes = SQLite.Expression<Int>("target_minutes")
    private let goalCurrentMinutes = SQLite.Expression<Int>("current_minutes")
    private let goalPeriodStart = SQLite.Expression<Date>("period_start")
    private let goalPeriodEnd = SQLite.Expression<Date>("period_end")
    private let goalCreatedAt = SQLite.Expression<Date>("created_at")

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/graft.sqlite3")
            try createTables()
        } catch {
            print("Database setup error: \(error)")
        }
    }

    private func createTables() throws {
        try db?.run(skills.create(ifNotExists: true) { t in
            t.column(skillId, primaryKey: .autoincrement)
            t.column(skillName)
            t.column(skillEmoji)
            t.column(skillIsActive, defaultValue: true)
            t.column(skillCreatedAt, defaultValue: Date())
            t.column(skillPriority, defaultValue: 0)
        })

        try db?.run(sessions.create(ifNotExists: true) { t in
            t.column(sessionId, primaryKey: .autoincrement)
            t.column(sessionSkillId)
            t.column(sessionDurationMinutes)
            t.column(sessionFeelRating)
            t.column(sessionNotes)
            t.column(sessionPracticedAt)
            t.column(sessionIsTimerBased, defaultValue: false)
        })

        try db?.run(plannedSessions.create(ifNotExists: true) { t in
            t.column(planId, primaryKey: .autoincrement)
            t.column(planSkillId)
            t.column(planSkillName)
            t.column(planSkillEmoji)
            t.column(planScheduledAt)
            t.column(planDurationMinutes, defaultValue: 30)
            t.column(planIsCompleted, defaultValue: false)
            t.column(planCreatedAt, defaultValue: Date())
        })

        try db?.run(timerPresets.create(ifNotExists: true) { t in
            t.column(presetId, primaryKey: .autoincrement)
            t.column(presetSkillId)
            t.column(presetDurationMinutes)
            t.column(presetLabel, defaultValue: "")
            t.column(presetCreatedAt, defaultValue: Date())
        })

        try db?.run(userGoals.create(ifNotExists: true) { t in
            t.column(goalId, primaryKey: .autoincrement)
            t.column(goalType)
            t.column(goalTargetMinutes)
            t.column(goalCurrentMinutes, defaultValue: 0)
            t.column(goalPeriodStart)
            t.column(goalPeriodEnd)
            t.column(goalCreatedAt, defaultValue: Date())
        })
    }

    // MARK: - Skills (Multiple)

    func getActiveSkills() -> [Skill] {
        guard let db = db else { return [] }
        var result: [Skill] = []
        do {
            let query = skills.filter(skillIsActive == true).order(skillPriority.asc)
            for row in try db.prepare(query) {
                result.append(Skill(
                    id: row[skillId],
                    name: row[skillName],
                    emoji: row[skillEmoji],
                    isActive: row[skillIsActive],
                    createdAt: row[skillCreatedAt]
                ))
            }
        } catch {
            print("getActiveSkills error: \(error)")
        }
        return result
    }

    func getActiveSkill() -> Skill? {
        return getActiveSkills().first
    }

    func getAllSkills() -> [Skill] {
        guard let db = db else { return [] }
        var result: [Skill] = []
        do {
            for row in try db.prepare(skills.order(skillCreatedAt.desc)) {
                result.append(Skill(
                    id: row[skillId],
                    name: row[skillName],
                    emoji: row[skillEmoji],
                    isActive: row[skillIsActive],
                    createdAt: row[skillCreatedAt]
                ))
            }
        } catch {
            print("getAllSkills error: \(error)")
        }
        return result
    }

    func getActiveSkillCount() -> Int {
        return getActiveSkills().count
    }

    @discardableResult
    func saveSkill(_ skill: inout Skill) -> Bool {
        guard let db = db else { return false }
        do {
            if let id = skill.id {
                let row = skills.filter(skillId == id)
                try db.run(row.update(
                    skillName <- skill.name,
                    skillEmoji <- skill.emoji,
                    skillIsActive <- skill.isActive
                ))
            } else {
                let count = getActiveSkillCount()
                let insert = skills.insert(
                    skillName <- skill.name,
                    skillEmoji <- skill.emoji,
                    skillIsActive <- skill.isActive,
                    skillCreatedAt <- skill.createdAt,
                    skillPriority <- count
                )
                skill.id = try db.run(insert)
            }
            return true
        } catch {
            print("saveSkill error: \(error)")
            return false
        }
    }

    func activateSkill(id: Int64) {
        guard let db = db else { return }
        do {
            let count = getActiveSkillCount()
            let row = skills.filter(skillId == id)
            try db.run(row.update(
                skillIsActive <- true,
                skillPriority <- count
            ))
        } catch {
            print("activateSkill error: \(error)")
        }
    }

    func deactivateSkill(id: Int64) {
        guard let db = db else { return }
        do {
            let row = skills.filter(skillId == id)
            try db.run(row.update(skillIsActive <- false))
            // Reorder remaining active skills
            reorderActiveSkills()
        } catch {
            print("deactivateSkill error: \(error)")
        }
    }

    func reorderActiveSkills() {
        guard let db = db else { return }
        let activeSkills = getActiveSkills()
        for (index, skill) in activeSkills.enumerated() {
            do {
                let row = skills.filter(skillId == skill.id!)
                try db.run(row.update(skillPriority <- index))
            } catch {
                print("reorderActiveSkills error: \(error)")
            }
        }
    }

    func deactivateAllSkills() {
        guard let db = db else { return }
        do {
            try db.run(skills.update(skillIsActive <- false))
        } catch {
            print("deactivateAllSkills error: \(error)")
        }
    }

    // MARK: - Sessions

    @discardableResult
    func saveSession(_ session: inout Session) -> Bool {
        guard let db = db else { return false }
        do {
            if let id = session.id {
                let row = sessions.filter(sessionId == id)
                try db.run(row.update(
                    sessionDurationMinutes <- session.durationMinutes,
                    sessionFeelRating <- session.feelRating,
                    sessionNotes <- session.notes,
                    sessionPracticedAt <- session.practicedAt
                ))
            } else {
                let insert = sessions.insert(
                    sessionSkillId <- session.skillId,
                    sessionDurationMinutes <- session.durationMinutes,
                    sessionFeelRating <- session.feelRating,
                    sessionNotes <- session.notes,
                    sessionPracticedAt <- session.practicedAt,
                    sessionIsTimerBased <- (session as? TimerSession)?.isTimerBased ?? false
                )
                session.id = try db.run(insert)
            }
            return true
        } catch {
            print("saveSession error: \(error)")
            return false
        }
    }

    func getSessions(for skillId: Int64, in month: Date) -> [Session] {
        guard let db = db else { return [] }
        var result: [Session] = []

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return []
        }

        do {
            let query = sessions
                .filter(sessionSkillId == skillId)
                .filter(sessionPracticedAt >= startOfMonth)
                .filter(sessionPracticedAt <= endOfMonth)
                .order(sessionPracticedAt.desc)

            for row in try db.prepare(query) {
                result.append(Session(
                    id: row[sessionId],
                    skillId: row[sessionSkillId],
                    durationMinutes: row[sessionDurationMinutes],
                    feelRating: row[sessionFeelRating],
                    notes: row[sessionNotes],
                    practicedAt: row[sessionPracticedAt]
                ))
            }
        } catch {
            print("getSessions error: \(error)")
        }
        return result
    }

    func getSessions(for skillId: Int64, on date: Date) -> [Session] {
        guard let db = db else { return [] }
        var result: [Session] = []

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }

        do {
            let query = sessions
                .filter(sessionSkillId == skillId)
                .filter(sessionPracticedAt >= startOfDay)
                .filter(sessionPracticedAt < endOfDay)
                .order(sessionPracticedAt.desc)

            for row in try db.prepare(query) {
                result.append(Session(
                    id: row[sessionId],
                    skillId: row[sessionSkillId],
                    durationMinutes: row[sessionDurationMinutes],
                    feelRating: row[sessionFeelRating],
                    notes: row[sessionNotes],
                    practicedAt: row[sessionPracticedAt]
                ))
            }
        } catch {
            print("getSessions error: \(error)")
        }
        return result
    }

    func getAllSessions(for skillId: Int64) -> [Session] {
        guard let db = db else { return [] }
        var result: [Session] = []
        do {
            let query = sessions
                .filter(sessionSkillId == skillId)
                .order(sessionPracticedAt.desc)

            for row in try db.prepare(query) {
                result.append(Session(
                    id: row[sessionId],
                    skillId: row[sessionSkillId],
                    durationMinutes: row[sessionDurationMinutes],
                    feelRating: row[sessionFeelRating],
                    notes: row[sessionNotes],
                    practicedAt: row[sessionPracticedAt]
                ))
            }
        } catch {
            print("getAllSessions error: \(error)")
        }
        return result
    }

    func getWeeklySessions(for skillId: Int64, weekStart: Date) -> [(date: Date, totalMinutes: Int)] {
        guard let db = db else { return [] }
        var result: [(Date, Int)] = []

        let calendar = Calendar.current
        for dayOffset in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            let startOfDay = calendar.startOfDay(for: dayDate)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }

            var totalMinutes = 0
            do {
                let query = sessions
                    .filter(sessionSkillId == skillId)
                    .filter(sessionPracticedAt >= startOfDay)
                    .filter(sessionPracticedAt < endOfDay)

                for row in try db.prepare(query) {
                    totalMinutes += row[sessionDurationMinutes]
                }
            } catch {
                print("getWeeklySessions inner error: \(error)")
            }
            result.append((startOfDay, totalMinutes))
        }
        return result
    }

    func getMonthlyTotalMinutes(for skillId: Int64, month: Date) -> Int {
        guard let db = db else { return 0 }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return 0
        }

        do {
            let query = sessions
                .filter(sessionSkillId == skillId)
                .filter(sessionPracticedAt >= startOfMonth)
                .filter(sessionPracticedAt <= endOfMonth)

            var total = 0
            for row in try db.prepare(query) {
                total += row[sessionDurationMinutes]
            }
            return total
        } catch {
            print("getMonthlyTotalMinutes error: \(error)")
            return 0
        }
    }

    func getPracticeDaysCount(for skillId: Int64, month: Date) -> Int {
        guard let db = db else { return 0 }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return 0
        }

        do {
            let query = sessions
                .filter(sessionSkillId == skillId)
                .filter(sessionPracticedAt >= startOfMonth)
                .filter(sessionPracticedAt <= endOfMonth)
                .select(sessionPracticedAt, true)

            var uniqueDays = Set<String>()
            for row in try db.prepare(query) {
                let day = calendar.startOfDay(for: row[sessionPracticedAt])
                uniqueDays.insert(day.description)
            }
            return uniqueDays.count
        } catch {
            print("getPracticeDaysCount error: \(error)")
            return 0
        }
    }

    // MARK: - Planned Sessions

    @discardableResult
    func savePlan(_ plan: inout PracticePlan) -> Bool {
        guard let db = db else { return false }
        do {
            if let id = plan.id {
                let row = plannedSessions.filter(planId == id)
                try db.run(row.update(
                    planScheduledAt <- plan.scheduledAt,
                    planDurationMinutes <- plan.durationMinutes,
                    planIsCompleted <- plan.isCompleted
                ))
            } else {
                let insert = plannedSessions.insert(
                    planSkillId <- plan.skillId,
                    planSkillName <- plan.skillName,
                    planSkillEmoji <- plan.skillEmoji,
                    planScheduledAt <- plan.scheduledAt,
                    planDurationMinutes <- plan.durationMinutes,
                    planIsCompleted <- plan.isCompleted,
                    planCreatedAt <- plan.createdAt
                )
                plan.id = try db.run(insert)
            }
            return true
        } catch {
            print("savePlan error: \(error)")
            return false
        }
    }

    func getUpcomingPlans(limit: Int = 10) -> [PracticePlan] {
        guard let db = db else { return [] }
        var result: [PracticePlan] = []
        let now = Date()
        do {
            let query = plannedSessions
                .filter(planIsCompleted == false)
                .filter(planScheduledAt >= now)
                .order(planScheduledAt.asc)
                .limit(limit)

            for row in try db.prepare(query) {
                result.append(PracticePlan(
                    id: row[planId],
                    skillId: row[planSkillId],
                    skillName: row[planSkillName],
                    skillEmoji: row[planSkillEmoji],
                    scheduledAt: row[planScheduledAt],
                    durationMinutes: row[planDurationMinutes],
                    isCompleted: row[planIsCompleted],
                    createdAt: row[planCreatedAt]
                ))
            }
        } catch {
            print("getUpcomingPlans error: \(error)")
        }
        return result
    }

    func getAllPlans() -> [PracticePlan] {
        guard let db = db else { return [] }
        var result: [PracticePlan] = []
        do {
            let query = plannedSessions.order(planScheduledAt.desc)
            for row in try db.prepare(query) {
                result.append(PracticePlan(
                    id: row[planId],
                    skillId: row[planSkillId],
                    skillName: row[planSkillName],
                    skillEmoji: row[planSkillEmoji],
                    scheduledAt: row[planScheduledAt],
                    durationMinutes: row[planDurationMinutes],
                    isCompleted: row[planIsCompleted],
                    createdAt: row[planCreatedAt]
                ))
            }
        } catch {
            print("getAllPlans error: \(error)")
        }
        return result
    }

    func markPlanCompleted(id: Int64) {
        guard let db = db else { return }
        do {
            let row = plannedSessions.filter(planId == id)
            try db.run(row.update(planIsCompleted <- true))
        } catch {
            print("markPlanCompleted error: \(error)")
        }
    }

    func deletePlan(id: Int64) {
        guard let db = db else { return }
        do {
            let row = plannedSessions.filter(planId == id)
            try db.run(row.delete())
        } catch {
            print("deletePlan error: \(error)")
        }
    }

    // MARK: - Analytics

    func getPersonalRecords() -> PersonalRecord {
        guard let db = db else { return .empty }

        var longestSession = 0
        var bestFeel = 0
        var totalLifetime = 0

        do {
            // Longest session
            let longestQuery = sessions.select(sessionDurationMinutes, true).order(sessionDurationMinutes.desc).limit(1)
            if let row = try db.pluck(longestQuery) {
                longestSession = row[sessionDurationMinutes]
            }

            // Best feel rating
            let bestFeelQuery = sessions.select(sessionFeelRating, true).order(sessionFeelRating.desc).limit(1)
            if let row = try db.pluck(bestFeelQuery) {
                bestFeel = row[sessionFeelRating]
            }

            // Total lifetime
            for row in try db.prepare(sessions) {
                totalLifetime += row[sessionDurationMinutes]
            }
        } catch {
            print("getPersonalRecords error: \(error)")
        }

        return PersonalRecord(
            longestSessionMinutes: longestSession,
            bestFeelRating: bestFeel,
            mostConsistentWeekMinutes: getMostConsistentWeekMinutes(),
            totalLifetimeMinutes: totalLifetime,
            longestStreakDays: getLongestStreakDays()
        )
    }

    private func getMostConsistentWeekMinutes() -> Int {
        guard let db = db else { return 0 }
        // Get all sessions grouped by week and find highest total
        let calendar = Calendar.current
        var weeklyTotals: [String: Int] = [:]

        do {
            for row in try db.prepare(sessions) {
                let date = row[sessionPracticedAt]
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
                let key = weekStart.description
                weeklyTotals[key, default: 0] += row[sessionDurationMinutes]
            }
        } catch {
            print("getMostConsistentWeekMinutes error: \(error)")
        }

        return weeklyTotals.values.max() ?? 0
    }

    private func getLongestStreakDays() -> Int {
        guard let db = db else { return 0 }
        let calendar = Calendar.current
        var practiceDays: Set<Date> = []

        do {
            for row in try db.prepare(sessions.select(sessionPracticedAt, true)) {
                let day = calendar.startOfDay(for: row[sessionPracticedAt])
                practiceDays.insert(day)
            }
        } catch {
            print("getLongestStreakDays error: \(error)")
        }

        let sortedDates = practiceDays.sorted()

        guard !sortedDates.isEmpty else { return 0 }

        var longestStreak = 1
        var currentStreak = 1

        for i in 1..<sortedDates.count {
            let diff = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            if diff == 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return longestStreak
    }

    func getSkillComparisonData() -> [SkillComparisonData] {
        let activeSkills = getActiveSkills()
        let calendar = Calendar.current
        let now = Date()
        var result: [SkillComparisonData] = []

        for skill in activeSkills {
            guard let skillId = skill.id else { continue }
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now

            let weekSessions = getWeeklySessions(for: skillId, weekStart: weekStart)
            let totalMinutes = weekSessions.reduce(0) { $0 + $1.totalMinutes }
            let allSessions = getAllSessions(for: skillId)

            let avgFeel = allSessions.isEmpty ? 0.0 : Double(allSessions.reduce(0) { $0 + $1.feelRating }) / Double(allSessions.count)

            result.append(SkillComparisonData(
                id: skillId,
                name: skill.name,
                emoji: skill.emoji,
                totalMinutes: totalMinutes,
                sessionCount: allSessions.count,
                avgFeelRating: avgFeel
            ))
        }

        return result
    }

    func getTrendData(weeks: Int = 8) -> [(weekStart: Date, totalMinutes: Int)] {
        guard let db = db else { return [] }
        let calendar = Calendar.current
        let now = Date()
        var result: [(Date, Int)] = []

        for weekOffset in (0..<weeks).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { continue }
            let normalizedWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)) ?? weekStart
            guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: normalizedWeekStart) else { continue }

            var totalMinutes = 0
            do {
                let query = sessions
                    .filter(sessionPracticedAt >= normalizedWeekStart)
                    .filter(sessionPracticedAt < weekEnd)

                for row in try db.prepare(query) {
                    totalMinutes += row[sessionDurationMinutes]
                }
            } catch {
                print("getTrendData error: \(error)")
            }
            result.append((normalizedWeekStart, totalMinutes))
        }

        return result
    }

    // MARK: - User Goals

    @discardableResult
    func saveGoal(_ goal: inout UserGoal) -> Bool {
        guard let db = db else { return false }
        do {
            if let id = goal.id {
                let row = userGoals.filter(goalId == id)
                try db.run(row.update(
                    goalTargetMinutes <- goal.targetMinutes,
                    goalCurrentMinutes <- goal.currentMinutes,
                    goalPeriodStart <- goal.periodStart,
                    goalPeriodEnd <- goal.periodEnd
                ))
            } else {
                let insert = userGoals.insert(
                    goalType <- goal.type.rawValue,
                    goalTargetMinutes <- goal.targetMinutes,
                    goalCurrentMinutes <- goal.currentMinutes,
                    goalPeriodStart <- goal.periodStart,
                    goalPeriodEnd <- goal.periodEnd,
                    goalCreatedAt <- goal.createdAt
                )
                goal.id = try db.run(insert)
            }
            return true
        } catch {
            print("saveGoal error: \(error)")
            return false
        }
    }

    func getActiveGoal(for type: UserGoal.GoalType) -> UserGoal? {
        guard let db = db else { return nil }
        let now = Date()
        do {
            let query = userGoals
                .filter(goalType == type.rawValue)
                .filter(goalPeriodEnd >= now)
                .order(goalCreatedAt.desc)
                .limit(1)

            if let row = try db.pluck(query) {
                return UserGoal(
                    id: row[goalId],
                    type: UserGoal.GoalType(rawValue: row[goalType]) ?? type,
                    targetMinutes: row[goalTargetMinutes],
                    currentMinutes: row[goalCurrentMinutes],
                    periodStart: row[goalPeriodStart],
                    periodEnd: row[goalPeriodEnd],
                    createdAt: row[goalCreatedAt]
                )
            }
        } catch {
            print("getActiveGoal error: \(error)")
        }
        return nil
    }

    func updateGoalProgress(id: Int64, minutes: Int) {
        guard let db = db else { return }
        do {
            let row = userGoals.filter(goalId == id)
            try db.run(row.update(goalCurrentMinutes <- minutes))
        } catch {
            print("updateGoalProgress error: \(error)")
        }
    }
}

// MARK: - TimerSession

struct TimerSession: Identifiable {
    var id: Int64?
    var skillId: Int64
    var durationMinutes: Int
    var feelRating: Int
    var notes: String?
    var practicedAt: Date
    var isTimerBased: Bool = true

    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}
