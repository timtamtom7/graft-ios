import Foundation
import SQLite

// MARK: - TeacherConnection

struct TeacherConnection: Identifiable, Equatable {
    var id: Int64?
    var teacherCode: String
    var studentCode: String
    var teacherName: String
    var studentName: String
    var createdAt: Date

    static func generateCode() -> String {
        String((0..<6).map { _ in "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".randomElement()! })
    }
}

// MARK: - TeacherAssignment

struct TeacherAssignment: Identifiable, Equatable {
    var id: Int64?
    var connectionId: Int64
    var skillName: String
    var skillEmoji: String
    var title: String
    var description: String?
    var targetMinutes: Int
    var targetSessions: Int
    var deadline: Date?
    var isCompleted: Bool
    var createdAt: Date

    var formattedTarget: String {
        let hours = targetMinutes / 60
        let mins = targetMinutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        }
        return "\(mins)m"
    }

    var deadlineText: String? {
        guard let deadline = deadline else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Due \(formatter.string(from: deadline))"
    }
}

// MARK: - StudentSession (linked to assignment)

struct StudentSession: Identifiable, Equatable {
    var id: Int64?
    var assignmentId: Int64
    var durationMinutes: Int
    var feelRating: Int
    var notes: String?
    var practicedAt: Date

    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}
