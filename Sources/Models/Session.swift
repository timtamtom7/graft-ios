import Foundation

struct Session: Identifiable, Equatable {
    var id: Int64?
    var skillId: Int64
    var durationMinutes: Int
    var feelRating: Int // 1-5
    var notes: String?
    var practicedAt: Date
    var isTimerBased: Bool = false

    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}
