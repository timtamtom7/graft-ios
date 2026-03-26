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

    // Teacher connections table
    private let teacherConnections = Table("teacher_connections")
    private let connId = SQLite.Expression<Int64>("id")
    private let connTeacherCode = SQLite.Expression<String>("teacher_code")
    private let connStudentCode = SQLite.Expression<String>("student_code")
    private let connTeacherName = SQLite.Expression<String>("teacher_name")
    private let connStudentName = SQLite.Expression<String>("student_name")
    private let connCreatedAt = SQLite.Expression<Date>("created_at")

    // Teacher assignments table
    private let teacherAssignments = Table("teacher_assignments")
    private let assignId = SQLite.Expression<Int64>("id")
    private let assignConnectionId = SQLite.Expression<Int64>("connection_id")
    private let assignSkillName = SQLite.Expression<String>("skill_name")
    private let assignSkillEmoji = SQLite.Expression<String>("skill_emoji")
    private let assignTitle = SQLite.Expression<String>("title")
    private let assignDescription = SQLite.Expression<String?>("description")
    private let assignTargetMinutes = SQLite.Expression<Int>("target_minutes")
    private let assignTargetSessions = SQLite.Expression<Int>("target_sessions")
    private let assignDeadline = SQLite.Expression<Date?>("deadline")
    private let assignIsCompleted = SQLite.Expression<Bool>("is_completed")
    private let assignCreatedAt = SQLite.Expression<Date>("created_at")

    // Student sessions under assignments
    private let studentSessions = Table("student_sessions")
    private let studSessId = SQLite.Expression<Int64>("id")
    private let studSessAssignmentId = SQLite.Expression<Int64>("assignment_id")
    private let studSessDurationMinutes = SQLite.Expression<Int>("duration_minutes")
    private let studSessFeelRating = SQLite.Expression<Int>("feel_rating")
    private let studSessNotes = SQLite.Expression<String?>("notes")
    private let studSessPracticedAt = SQLite.Expression<Date>("practiced_at")

    // App tier table
    private let appTier = Table("app_tier")
    private let tierId = SQLite.Expression<Int64>("id")
    private let tierType = SQLite.Expression<String>("type")
    private let tierSetAt = SQLite.Expression<Date>("set_at")

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
                print("Database setup error: could not find documents directory")
                return
            }
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

        // Teacher connections table
        try db?.run(teacherConnections.create(ifNotExists: true) { t in
            t.column(connId, primaryKey: .autoincrement)
            t.column(connTeacherCode)
            t.column(connStudentCode)
            t.column(connTeacherName)
            t.column(connStudentName)
            t.column(connCreatedAt, defaultValue: Date())
        })

        // Teacher assignments table
        try db?.run(teacherAssignments.create(ifNotExists: true) { t in
            t.column(assignId, primaryKey: .autoincrement)
            t.column(assignConnectionId)
            t.column(assignSkillName)
            t.column(assignSkillEmoji)
            t.column(assignTitle)
            t.column(assignDescription)
            t.column(assignTargetMinutes)
            t.column(assignTargetSessions, defaultValue: 1)
            t.column(assignDeadline)
            t.column(assignIsCompleted, defaultValue: false)
            t.column(assignCreatedAt, defaultValue: Date())
        })

        // Student sessions under assignments
        try db?.run(studentSessions.create(ifNotExists: true) { t in
            t.column(studSessId, primaryKey: .autoincrement)
            t.column(studSessAssignmentId)
            t.column(studSessDurationMinutes)
            t.column(studSessFeelRating)
            t.column(studSessNotes)
            t.column(studSessPracticedAt)
        })

        // App tier table
        try db?.run(appTier.create(ifNotExists: true) { t in
            t.column(tierId, primaryKey: .autoincrement)
            t.column(tierType, defaultValue: SubscriptionTier.free.rawValue)
            t.column(tierSetAt, defaultValue: Date())
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
                    sessionPracticedAt <- session.practicedAt,
                    sessionIsTimerBased <- session.isTimerBased
                ))
            } else {
                let insert = sessions.insert(
                    sessionSkillId <- session.skillId,
                    sessionDurationMinutes <- session.durationMinutes,
                    sessionFeelRating <- session.feelRating,
                    sessionNotes <- session.notes,
                    sessionPracticedAt <- session.practicedAt,
                    sessionIsTimerBased <- session.isTimerBased
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
                    practicedAt: row[sessionPracticedAt],
                    isTimerBased: row[sessionIsTimerBased]
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
                    practicedAt: row[sessionPracticedAt],
                    isTimerBased: row[sessionIsTimerBased]
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
                    practicedAt: row[sessionPracticedAt],
                    isTimerBased: row[sessionIsTimerBased]
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

    /// Delete a session by ID
    func deleteSession(id: Int64) -> Bool {
        guard let db = db else { return false }
        do {
            let row = sessions.filter(sessionId == id)
            try db.run(row.delete())
            return true
        } catch {
            print("deleteSession error: \(error)")
            return false
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

    // MARK: - Teacher Connections

    @discardableResult
    func saveTeacherConnection(_ conn: inout TeacherConnection) -> Bool {
        guard let db = db else { return false }
        do {
            if let id = conn.id {
                let row = teacherConnections.filter(connId == id)
                try db.run(row.update(
                    connTeacherName <- conn.teacherName,
                    connStudentName <- conn.studentName
                ))
            } else {
                let insert = teacherConnections.insert(
                    connTeacherCode <- conn.teacherCode,
                    connStudentCode <- conn.studentCode,
                    connTeacherName <- conn.teacherName,
                    connStudentName <- conn.studentName,
                    connCreatedAt <- conn.createdAt
                )
                conn.id = try db.run(insert)
            }
            return true
        } catch {
            print("saveTeacherConnection error: \(error)")
            return false
        }
    }

    func getTeacherConnection(code: String) -> TeacherConnection? {
        guard let db = db else { return nil }
        do {
            let query = teacherConnections.filter(connTeacherCode == code).limit(1)
            if let row = try db.pluck(query) {
                return TeacherConnection(
                    id: row[connId],
                    teacherCode: row[connTeacherCode],
                    studentCode: row[connStudentCode],
                    teacherName: row[connTeacherName],
                    studentName: row[connStudentName],
                    createdAt: row[connCreatedAt]
                )
            }
        } catch {
            print("getTeacherConnection error: \(error)")
        }
        return nil
    }

    func getStudentConnections(studentCode: String) -> [TeacherConnection] {
        guard let db = db else { return [] }
        var result: [TeacherConnection] = []
        do {
            let query = teacherConnections.filter(connStudentCode == studentCode)
            for row in try db.prepare(query) {
                result.append(TeacherConnection(
                    id: row[connId],
                    teacherCode: row[connTeacherCode],
                    studentCode: row[connStudentCode],
                    teacherName: row[connTeacherName],
                    studentName: row[connStudentName],
                    createdAt: row[connCreatedAt]
                ))
            }
        } catch {
            print("getStudentConnections error: \(error)")
        }
        return result
    }

    func getTeacherConnections() -> [TeacherConnection] {
        guard let db = db else { return [] }
        var result: [TeacherConnection] = []
        do {
            for row in try db.prepare(teacherConnections) {
                result.append(TeacherConnection(
                    id: row[connId],
                    teacherCode: row[connTeacherCode],
                    studentCode: row[connStudentCode],
                    teacherName: row[connTeacherName],
                    studentName: row[connStudentName],
                    createdAt: row[connCreatedAt]
                ))
            }
        } catch {
            print("getTeacherConnections error: \(error)")
        }
        return result
    }

    func deleteTeacherConnection(id: Int64) {
        guard let db = db else { return }
        do {
            // Delete associated assignments first
            let assignments = teacherAssignments.filter(assignConnectionId == id)
            try db.run(assignments.delete())
            // Delete connection
            let row = teacherConnections.filter(connId == id)
            try db.run(row.delete())
        } catch {
            print("deleteTeacherConnection error: \(error)")
        }
    }

    // MARK: - Teacher Assignments

    @discardableResult
    func saveTeacherAssignment(_ assignment: inout TeacherAssignment) -> Bool {
        guard let db = db else { return false }
        do {
            if let id = assignment.id {
                let row = teacherAssignments.filter(assignId == id)
                try db.run(row.update(
                    assignTitle <- assignment.title,
                    assignDescription <- assignment.description,
                    assignTargetMinutes <- assignment.targetMinutes,
                    assignTargetSessions <- assignment.targetSessions,
                    assignDeadline <- assignment.deadline,
                    assignIsCompleted <- assignment.isCompleted
                ))
            } else {
                let insert = teacherAssignments.insert(
                    assignConnectionId <- assignment.connectionId,
                    assignSkillName <- assignment.skillName,
                    assignSkillEmoji <- assignment.skillEmoji,
                    assignTitle <- assignment.title,
                    assignDescription <- assignment.description,
                    assignTargetMinutes <- assignment.targetMinutes,
                    assignTargetSessions <- assignment.targetSessions,
                    assignDeadline <- assignment.deadline,
                    assignIsCompleted <- assignment.isCompleted,
                    assignCreatedAt <- assignment.createdAt
                )
                assignment.id = try db.run(insert)
            }
            return true
        } catch {
            print("saveTeacherAssignment error: \(error)")
            return false
        }
    }

    func getAssignmentsForConnection(_ connectionId: Int64) -> [TeacherAssignment] {
        guard let db = db else { return [] }
        var result: [TeacherAssignment] = []
        do {
            let query = teacherAssignments.filter(assignConnectionId == connectionId).order(assignCreatedAt.desc)
            for row in try db.prepare(query) {
                result.append(TeacherAssignment(
                    id: row[assignId],
                    connectionId: row[assignConnectionId],
                    skillName: row[assignSkillName],
                    skillEmoji: row[assignSkillEmoji],
                    title: row[assignTitle],
                    description: row[assignDescription],
                    targetMinutes: row[assignTargetMinutes],
                    targetSessions: row[assignTargetSessions],
                    deadline: row[assignDeadline],
                    isCompleted: row[assignIsCompleted],
                    createdAt: row[assignCreatedAt]
                ))
            }
        } catch {
            print("getAssignmentsForConnection error: \(error)")
        }
        return result
    }

    func getAllTeacherAssignments() -> [TeacherAssignment] {
        guard let db = db else { return [] }
        var result: [TeacherAssignment] = []
        do {
            let query = teacherAssignments.order(assignCreatedAt.desc)
            for row in try db.prepare(query) {
                result.append(TeacherAssignment(
                    id: row[assignId],
                    connectionId: row[assignConnectionId],
                    skillName: row[assignSkillName],
                    skillEmoji: row[assignSkillEmoji],
                    title: row[assignTitle],
                    description: row[assignDescription],
                    targetMinutes: row[assignTargetMinutes],
                    targetSessions: row[assignTargetSessions],
                    deadline: row[assignDeadline],
                    isCompleted: row[assignIsCompleted],
                    createdAt: row[assignCreatedAt]
                ))
            }
        } catch {
            print("getAllTeacherAssignments error: \(error)")
        }
        return result
    }

    func deleteTeacherAssignment(id: Int64) {
        guard let db = db else { return }
        do {
            let sessions = studentSessions.filter(studSessAssignmentId == id)
            try db.run(sessions.delete())
            let row = teacherAssignments.filter(assignId == id)
            try db.run(row.delete())
        } catch {
            print("deleteTeacherAssignment error: \(error)")
        }
    }

    func markAssignmentCompleted(id: Int64) {
        guard let db = db else { return }
        do {
            let row = teacherAssignments.filter(assignId == id)
            try db.run(row.update(assignIsCompleted <- true))
        } catch {
            print("markAssignmentCompleted error: \(error)")
        }
    }

    // MARK: - Student Sessions

    @discardableResult
    func saveStudentSession(_ session: inout StudentSession) -> Bool {
        guard let db = db else { return false }
        do {
            if let id = session.id {
                let row = studentSessions.filter(studSessId == id)
                try db.run(row.update(
                    studSessDurationMinutes <- session.durationMinutes,
                    studSessFeelRating <- session.feelRating,
                    studSessNotes <- session.notes,
                    studSessPracticedAt <- session.practicedAt
                ))
            } else {
                let insert = studentSessions.insert(
                    studSessAssignmentId <- session.assignmentId,
                    studSessDurationMinutes <- session.durationMinutes,
                    studSessFeelRating <- session.feelRating,
                    studSessNotes <- session.notes,
                    studSessPracticedAt <- session.practicedAt
                )
                session.id = try db.run(insert)
            }
            return true
        } catch {
            print("saveStudentSession error: \(error)")
            return false
        }
    }

    func getStudentSessions(for assignmentId: Int64) -> [StudentSession] {
        guard let db = db else { return [] }
        var result: [StudentSession] = []
        do {
            let query = studentSessions.filter(studSessAssignmentId == assignmentId).order(studSessPracticedAt.desc)
            for row in try db.prepare(query) {
                result.append(StudentSession(
                    id: row[studSessId],
                    assignmentId: row[studSessAssignmentId],
                    durationMinutes: row[studSessDurationMinutes],
                    feelRating: row[studSessFeelRating],
                    notes: row[studSessNotes],
                    practicedAt: row[studSessPracticedAt]
                ))
            }
        } catch {
            print("getStudentSessions error: \(error)")
        }
        return result
    }

    func getTotalMinutesForAssignment(_ assignmentId: Int64) -> Int {
        guard let db = db else { return 0 }
        var total = 0
        do {
            let query = studentSessions.filter(studSessAssignmentId == assignmentId)
            for row in try db.prepare(query) {
                total += row[studSessDurationMinutes]
            }
        } catch {
            print("getTotalMinutesForAssignment error: \(error)")
        }
        return total
    }

    func getStudentProgressForConnection(_ connectionId: Int64) -> (totalMinutes: Int, sessionsCount: Int) {
        let assignments = getAssignmentsForConnection(connectionId)
        var totalMinutes = 0
        var sessionsCount = 0
        for assignment in assignments {
            guard let id = assignment.id else { continue }
            let sessions = getStudentSessions(for: id)
            sessionsCount += sessions.count
            totalMinutes += sessions.reduce(0) { $0 + $1.durationMinutes }
        }
        return (totalMinutes, sessionsCount)
    }

    // MARK: - App Tier

    func getCurrentTier() -> SubscriptionTier {
        guard let db = db else { return .free }
        do {
            if let row = try db.pluck(appTier) {
                return SubscriptionTier(rawValue: row[tierType]) ?? .free
            }
        } catch {
            print("getCurrentTier error: \(error)")
        }
        return .free
    }

    func setTier(_ tier: SubscriptionTier) {
        guard let db = db else { return }
        do {
            if let row = try db.pluck(appTier) {
                try db.run(appTier.update(
                    tierType <- tier.rawValue,
                    tierSetAt <- Date()
                ))
            } else {
                try db.run(appTier.insert(
                    tierType <- tier.rawValue,
                    tierSetAt <- Date()
                ))
            }
        } catch {
            print("setTier error: \(error)")
        }
    }

    // MARK: - AI Pattern Analysis

    func getAIPatternInsights() -> [String] {
        var insights: [String] = []
        let sessions = getAllSessionsForAllSkills()
        guard sessions.count >= 5 else { return [] }

        let calendar = Calendar.current

        // Best time of day
        let hourGroups = Dictionary(grouping: sessions) { session in
            calendar.component(.hour, from: session.practicedAt)
        }
        var bestHourAvg: (hour: Int, avgFeel: Double) = (12, 0)
        for (hour, hourSessions) in hourGroups {
            guard hourSessions.count >= 2 else { continue }
            let avgFeel = Double(hourSessions.reduce(0) { $0 + $1.feelRating }) / Double(hourSessions.count)
            if avgFeel > bestHourAvg.avgFeel {
                bestHourAvg = (hour, avgFeel)
            }
        }
        if bestHourAvg.avgFeel > 0 {
            let timeLabel = timeOfDayLabel(bestHourAvg.hour)
            insights.append("Your best sessions are around \(timeLabel)")
        }

        // Timer vs manual sessions
        let timerSessions = sessions.filter { $0.isTimerBased }
        let manualSessions = sessions.filter { !$0.isTimerBased }
        if !timerSessions.isEmpty && !manualSessions.isEmpty {
            let timerAvg = Double(timerSessions.reduce(0) { $0 + $1.durationMinutes }) / Double(timerSessions.count)
            let manualAvg = Double(manualSessions.reduce(0) { $0 + $1.durationMinutes }) / Double(manualSessions.count)
            if timerAvg > manualAvg * 1.2 {
                insights.append("You practice \(Int((timerAvg / manualAvg - 1) * 100))% longer when using the timer")
            }
        }

        // Weekday vs weekend
        let weekdaySessions = sessions.filter { !calendar.isDateInWeekend($0.practicedAt) }
        let weekendSessions = sessions.filter { calendar.isDateInWeekend($0.practicedAt) }
        if !weekdaySessions.isEmpty && !weekendSessions.isEmpty {
            let weekdayAvg = Double(weekdaySessions.count) / max(5, 1)
            let weekendAvg = Double(weekendSessions.count) / max(2, 1)
            if weekdayAvg > weekendAvg * 1.3 {
                insights.append("You practice more on weekdays")
            } else if weekendAvg > weekdayAvg * 1.3 {
                insights.append("You practice more on weekends")
            }
        }

        // Streak insight
        let streak = getLongestStreakDays()
        if streak >= 7 {
            insights.append("Your best streak is \(streak) days — keep building!")
        }

        // Session frequency
        if sessions.count >= 10 {
            let recent = sessions.prefix(sessions.count / 2)
            let older = sessions.suffix(sessions.count / 2)
            let recentAvg = Double(recent.reduce(0) { $0 + $1.durationMinutes }) / Double(max(recent.count, 1))
            let olderAvg = Double(older.reduce(0) { $0 + $1.durationMinutes }) / Double(max(older.count, 1))
            if recentAvg > olderAvg * 1.3 {
                insights.append("Your recent sessions are getting longer — great momentum!")
            } else if recentAvg < olderAvg * 0.7 {
                insights.append("Your sessions have been shorter lately — try the timer for focus")
            }
        }

        return insights
    }

    private func getAllSessionsForAllSkills() -> [Session] {
        guard let db = db else { return [] }
        var result: [Session] = []
        do {
            for row in try db.prepare(sessions.order(sessionPracticedAt.desc)) {
                result.append(Session(
                    id: row[sessionId],
                    skillId: row[sessionSkillId],
                    durationMinutes: row[sessionDurationMinutes],
                    feelRating: row[sessionFeelRating],
                    notes: row[sessionNotes],
                    practicedAt: row[sessionPracticedAt],
                    isTimerBased: row[sessionIsTimerBased]
                ))
            }
        } catch {
            print("getAllSessionsForAllSkills error: \(error)")
        }
        return result
    }

    private func timeOfDayLabel(_ hour: Int) -> String {
        switch hour {
        case 5..<12: return "morning"
        case 12..<14: return "midday"
        case 14..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }

    // MARK: - R7: Advanced AI Habit Intelligence

    struct HabitAIInsights: Codable {
        var streakPrediction: Int // predicted streak if current pace maintained
        var riskLevel: String // "low", "medium", "high"
        var optimalReminderTime: String? // "9:00 AM"
        var difficultyScore: Int // 1-10
        var weeklyPattern: [Bool] // [true,true,false,true,true,true,false]
        var motivationalMessage: String
        var suggestions: [String]
    }

    func getHabitAIInsights(for skillId: Int64) -> HabitAIInsights? {
        let allSessions = getAllSessionsForAllSkills()
        let sessions = allSessions.filter { $0.skillId == skillId }
        guard sessions.count >= 5 else { return nil }

        let recent = sessions.prefix(14) // last 2 weeks
        let weeklyPattern = computeWeeklyPattern(sessions: Array(sessions))
        let streakPred = predictStreak(sessions: Array(recent))
        let risk = assessRiskLevel(sessions: Array(recent))
        let optimalTime = findOptimalReminderTime(sessions: Array(sessions))
        let difficulty = calculateDifficulty(sessions: Array(sessions))

        var suggestions: [String] = []
        if risk == "high" { suggestions.append("Consider reducing your daily goal to maintain momentum") }
        if difficulty > 7 { suggestions.append("This habit feels difficult — try breaking it into smaller steps") }
        if weeklyPattern.filter({ $0 }).count < 4 { suggestions.append("Try practicing at the same time each day for consistency") }

        let motivationalMessage: String
        let streakCount = sessions.prefix(7).filter { Calendar.current.isDate($0.practicedAt, inSameDayAs: sessions.first?.practicedAt ?? Date()) }.count
        if streakCount >= 7 {
            motivationalMessage = "Amazing! You've been consistent this week. Keep the momentum going!"
        } else if streakCount >= 4 {
            motivationalMessage = "You're building a great habit! Just a few more days to lock it in."
        } else {
            motivationalMessage = "Every session counts. Start small and build from here."
        }

        return HabitAIInsights(
            streakPrediction: streakPred,
            riskLevel: risk,
            optimalReminderTime: optimalTime,
            difficultyScore: difficulty,
            weeklyPattern: weeklyPattern,
            motivationalMessage: motivationalMessage,
            suggestions: suggestions
        )
    }

    private func computeWeeklyPattern(sessions: [Session]) -> [Bool] {
        // Last 7 days, each day: did user practice?
        var pattern = [Bool](repeating: false, count: 7)
        let calendar = Calendar.current
        for session in sessions {
            let daysAgo = calendar.dateComponents([.day], from: session.practicedAt, to: Date()).day ?? 0
            if daysAgo < 7 {
                pattern[6 - daysAgo] = true
            }
        }
        return pattern
    }

    private func predictStreak(sessions: [Session]) -> Int {
        // Predict streak based on recent consistency
        let recentDays = Set(sessions.map { Calendar.current.startOfDay(for: $0.practicedAt) })
        let sortedDays = recentDays.sorted(by: >)
        var predictedStreak = 0
        var currentDate = Date()

        for day in sortedDays {
            let diff = Calendar.current.dateComponents([.day], from: day, to: currentDate).day ?? 0
            if diff <= 1 {
                predictedStreak += 1
                currentDate = day
            } else {
                break
            }
        }
        return predictedStreak + sessions.count / 3 // add some buffer based on session count
    }

    private func assessRiskLevel(sessions: [Session]) -> String {
        // High risk: declining session frequency, low feel ratings
        let recent = sessions.prefix(5)
        let older = sessions.dropFirst(5).prefix(5)

        if older.isEmpty { return "low" }

        let recentAvgFeel = Double(recent.reduce(0) { $0 + $1.feelRating }) / Double(max(recent.count, 1))
        let olderAvgFeel = Double(older.reduce(0) { $0 + $1.feelRating }) / Double(max(older.count, 1))

        if recentAvgFeel < olderAvgFeel - 1.0 { return "high" }
        if recentAvgFeel < olderAvgFeel - 0.5 { return "medium" }
        return "low"
    }

    private func findOptimalReminderTime(sessions: [Session]) -> String? {
        let calendar = Calendar.current
        var hourFrequency: [Int: Int] = [:]

        for session in sessions {
            let hour = calendar.component(.hour, from: session.practicedAt)
            hourFrequency[hour, default: 0] += 1
        }

        guard let bestHour = hourFrequency.max(by: { $0.value < $1.value })?.key else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        var components = DateComponents()
        components.hour = bestHour
        components.minute = 0

        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return nil
    }

    private func calculateDifficulty(sessions: [Session]) -> Int {
        // Difficulty based on: session abandonment rate, low feel ratings, short durations
        guard !sessions.isEmpty else { return 5 }

        let avgFeel = Double(sessions.reduce(0) { $0 + $1.feelRating }) / Double(sessions.count)
        let avgDuration = Double(sessions.reduce(0) { $0 + $1.durationMinutes }) / Double(sessions.count)

        // Lower feel + shorter duration = higher difficulty
        var score = 5 // default medium

        if avgFeel < 2.5 { score += 2 }
        else if avgFeel < 3.5 { score += 1 }

        if avgDuration < 10 { score += 1 }
        else if avgDuration > 20 { score -= 1 }

        return min(10, max(1, score))
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
