import Foundation

// MARK: - AI Coach Service

final class AICoachService: @unchecked Sendable {
    static let shared = AICoachService()

    private init() {}

    // MARK: - Session Suggestion

    /// Analyze practice patterns and suggest an optimal next session.
    func suggestNextSession(for skill: Skill, history: [Session]) -> SessionSuggestion {
        let sorted = history.sorted { $0.practicedAt > $1.practicedAt }
        let streak = calculateCurrentStreak(from: sorted)
        let recentAvg = averageDuration(last: 5, sessions: sorted)
        let lastSession = sorted.first
        let feltTough = (lastSession?.feelRating ?? 0) <= 2

        // Determine base suggestion from streak
        let (baseDuration, baseFocus, baseWarmup, baseReason): (Int, String, String, String)

        if streak == 0 {
            baseDuration = 20
            baseFocus = "Revisit fundamentals"
            baseWarmup = "5 minutes of light review"
            baseReason = "You haven't practiced recently. Ease back in to rebuild the habit."
        } else if streak <= 3 {
            baseDuration = max(25, Int(Double(recentAvg) * 0.9))
            baseFocus = "Steady skill building"
            baseWarmup = "3–5 minute warmup at low intensity"
            baseReason = "You're building momentum with a \(streak)-day streak. Keep it going!"
        } else if streak <= 7 {
            baseDuration = max(30, Int(Double(recentAvg) * 1.1))
            baseFocus = "Push your edge — try something harder"
            baseWarmup = "5 minutes with increasing intensity"
            baseReason = "\(streak)-day streak! You're in momentum mode. This is the time to go deeper."
        } else {
            baseDuration = max(45, Int(Double(recentAvg) * 1.2))
            baseFocus = "Advanced technique or new challenge"
            baseWarmup = "10-minute structured warmup with progressive difficulty"
            baseReason = "Exceptional \(streak)-day streak. Your AI coach recommends a deeper session."
        }

        // Adjust if last session felt tough
        let duration = feltTough ? min(baseDuration, 30) : baseDuration
        let reason = feltTough ? "Last session felt tough. Keep it shorter and focus on enjoyment." : baseReason

        return SessionSuggestion(
            durationMinutes: duration,
            focusArea: baseFocus,
            warmup: baseWarmup,
            reason: reason
        )
    }

    // MARK: - Flow State Detection

    /// Detects if the most recent session qualifies as a flow state.
    /// Criteria: >45 min, no interruptions, followed routine (timer-based or warmup detected).
    func detectFlowState(sessions: [Session]) -> Bool {
        guard let last = sessions.max(by: { $0.practicedAt < $1.practicedAt }) else {
            return false
        }
        let isLongEnough = last.durationMinutes > 45
        let noInterruptions = !(last.hadInterruptions ?? false)
        let followedRoutine = last.followedRoutine ?? last.isTimerBased
        return isLongEnough && noInterruptions && followedRoutine
    }

    /// Returns true if the user has achieved flow in any recent session.
    func hasRecentFlow(sessions: [Session]) -> Bool {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recent = sessions.filter { $0.practicedAt >= cutoff }
        return detectFlowState(sessions: recent)
    }

    // MARK: - Practice Tips

    /// Returns a contextual practice tip based on skill type and recent performance.
    func getPracticeTip(for skill: Skill) -> String {
        let tips = contextualTips(for: skill.name)
        return tips.randomElement() ?? "Consistent practice beats long, sporadic sessions."
    }

    private func contextualTips(for skillName: String) -> [String] {
        let lower = skillName.lowercased()

        if lower.contains("piano") || lower.contains("guitar") || lower.contains("violin") || lower.contains("music") {
            return [
                "Start each session with your hardest piece — you'll have the most focus.",
                "Isolate the 4-bar passage that's tripping you up and repeat it 10 times.",
                "Playing slowly is NOT a sign of weakness. It's precision practice.",
                "End every session by playing something you love — it reinforces joy.",
                "Mental practice counts too: visualize the piece when you can't play."
            ]
        } else if lower.contains("code") || lower.contains("programming") || lower.contains("algorithm") {
            return [
                "Rubber duck debugging: explain your bug out loud before searching for answers.",
                "Write the tests before the code. Red-green-refactor keeps you honest.",
                "After 90 minutes, take a real break. Code written tired is code rewritten tomorrow.",
                "Start with the simplest possible solution. Complexity is the enemy.",
                "Review your code from yesterday — future you will thank present you."
            ]
        } else if lower.contains("run") || lower.contains("swim") || lower.contains("cycling") || lower.contains("fitness") || lower.contains("workout") || lower.contains("gym") {
            return [
                "The first 10 minutes are the hardest. Commit to just starting.",
                "Progressive overload: add 1 more rep or 2 more minutes each week.",
                "Rest days aren't lazy — they're when your body actually gets stronger.",
                "Track one metric consistently. Progress becomes visible.",
                "Morning practice sets the tone for the entire day."
            ]
        } else if lower.contains("language") || lower.contains("spanish") || lower.contains("french") || lower.contains("chinese") {
            return [
                "Spaced repetition is your superpower. Review before you forget.",
                "30 minutes of focused listening beats 2 hours of passive study.",
                "Speak out loud — even to an empty room. Mouth muscles need training.",
                "Learn the 300 most common words first. They cover 80% of conversation.",
                "Watch something you love in your target language with subtitles."
            ]
        } else {
            return [
                "Consistent short sessions beat marathon cramming every time.",
                "Break your practice into: warmup → main focus → cool down.",
                "Track your sessions. What gets measured gets improved.",
                "If you missed a day, don't double up — just get back on track tomorrow.",
                "Practice the hard stuff first while your focus is fresh.",
                "Sleep after learning. Your brain consolidates memories during rest.",
                "Set a specific goal for each session: vague practice = vague results."
            ]
        }
    }

    // MARK: - Streak Risk Detection

    /// Returns true if the user's streak is at risk of breaking.
    func isStreakAtRisk(history: [Session]) -> Bool {
        guard let lastSession = history.max(by: { $0.practicedAt < $1.practicedAt }) else {
            return true // Never practiced
        }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastSession.practicedAt)
        let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

        if daysDiff == 0 {
            return false // Practiced today
        } else if daysDiff == 1 {
            return true // Last practice was yesterday — needs to practice today
        } else {
            return true // Streak already broken
        }
    }

    // MARK: - Helpers

    private func calculateCurrentStreak(from sessions: [Session]) -> Int {
        let calendar = Calendar.current
        let uniqueDays = sessions
            .map { calendar.startOfDay(for: $0.practicedAt) }
            .reduce(into: Set<Date>()) { $0.insert($1) }

        guard !uniqueDays.isEmpty else { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // If today has no session, start checking from yesterday
        if !uniqueDays.contains(checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                return 0
            }
            checkDate = yesterday
        }

        while uniqueDays.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        return streak
    }

    private func averageDuration(last n: Int, sessions: [Session]) -> Int {
        guard !sessions.isEmpty else { return 30 }
        let top = Array(sessions.prefix(n))
        let total = top.reduce(0) { $0 + $1.durationMinutes }
        return total / top.count
    }
}

// MARK: - Session Suggestion

struct SessionSuggestion {
    let durationMinutes: Int
    let focusArea: String
    let warmup: String
    let reason: String

    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}
