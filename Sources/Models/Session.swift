import Foundation

struct Session: Identifiable, Equatable {
    var id: Int64?
    var skillId: Int64
    var durationMinutes: Int
    var feelRating: Int // 1-5
    var notes: String?
    var practicedAt: Date
    var isTimerBased: Bool = false

    // MARK: - Flow State Indicators
    /// Whether the session was interrupted (phone call, distraction, etc.)
    var hadInterruptions: Bool?
    /// Whether the session followed a warmup → main → cooldown structure
    var followedRoutine: Bool?

    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    /// True if this session qualifies as a flow state:
    /// duration > 45 min, no interruptions, and followed a routine (or was timer-based).
    var isFlowState: Bool {
        durationMinutes > 45 && !(hadInterruptions ?? false) && (followedRoutine ?? isTimerBased)
    }
}
