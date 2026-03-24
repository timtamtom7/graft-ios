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

    // Sessions table
    private let sessions = Table("sessions")
    private let sessionId = SQLite.Expression<Int64>("id")
    private let sessionSkillId = SQLite.Expression<Int64>("skill_id")
    private let sessionDurationMinutes = SQLite.Expression<Int>("duration_minutes")
    private let sessionFeelRating = SQLite.Expression<Int>("feel_rating")
    private let sessionNotes = SQLite.Expression<String?>("notes")
    private let sessionPracticedAt = SQLite.Expression<Date>("practiced_at")

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
        })

        try db?.run(sessions.create(ifNotExists: true) { t in
            t.column(sessionId, primaryKey: .autoincrement)
            t.column(sessionSkillId)
            t.column(sessionDurationMinutes)
            t.column(sessionFeelRating)
            t.column(sessionNotes)
            t.column(sessionPracticedAt)
        })
    }

    // MARK: - Skills

    func getActiveSkill() -> Skill? {
        guard let db = db else { return nil }
        do {
            let query = skills.filter(skillIsActive == true).limit(1)
            if let row = try db.pluck(query) {
                return Skill(
                    id: row[skillId],
                    name: row[skillName],
                    emoji: row[skillEmoji],
                    isActive: row[skillIsActive],
                    createdAt: row[skillCreatedAt]
                )
            }
        } catch {
            print("getActiveSkill error: \(error)")
        }
        return nil
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
                let insert = skills.insert(
                    skillName <- skill.name,
                    skillEmoji <- skill.emoji,
                    skillIsActive <- skill.isActive,
                    skillCreatedAt <- skill.createdAt
                )
                skill.id = try db.run(insert)
            }
            return true
        } catch {
            print("saveSkill error: \(error)")
            return false
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
                    sessionPracticedAt <- session.practicedAt
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
}
