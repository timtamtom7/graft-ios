import Foundation
import SwiftUI

// R11: Milestones & Achievements for Graft
// Skill-specific milestones, lifetime achievements, seasonal challenges
@MainActor
final class AchievementService: ObservableObject {
    static let shared = AchievementService()

    @Published var achievements: [Achievement] = []
    @Published var unlockedAchievements: Set<UUID> = []
    @Published var customMilestones: [CustomMilestone] = []

    struct Achievement: Identifiable, Codable {
        let id: UUID
        let title: String
        let description: String
        let icon: String
        let type: AchievementType
        let requirement: Int
        var isUnlocked: Bool
        var unlockedAt: Date?

        enum AchievementType: String, Codable {
            case streak
            case totalHours
            case consistency
            case milestone
            case challenge
        }
    }

    struct CustomMilestone: Identifiable, Codable {
        let id: UUID
        let title: String
        let skillName: String?
        let targetDays: Int
        var currentDays: Int
    }

    // Pre-defined achievements
    static let predefinedAchievements: [Achievement] = [
        // Streak achievements
        Achievement(id: UUID(), title: "7-Day Streak", description: "Practice for 7 days straight", icon: "flame.fill", type: .streak, requirement: 7, isUnlocked: false, unlockedAt: nil),
        Achievement(id: UUID(), title: "30-Day Streak", description: "Practice for 30 days straight", icon: "flame", type: .streak, requirement: 30, isUnlocked: false, unlockedAt: nil),
        Achievement(id: UUID(), title: "100-Day Streak", description: "Practice for 100 days straight", icon: "star.fill", type: .streak, requirement: 100, isUnlocked: false, unlockedAt: nil),
        // Total hours
        Achievement(id: UUID(), title: "10 Hour Club", description: "Total of 10 practice hours", icon: "clock.fill", type: .totalHours, requirement: 10, isUnlocked: false, unlockedAt: nil),
        Achievement(id: UUID(), title: "100 Hour Master", description: "Total of 100 practice hours", icon: "trophy.fill", type: .totalHours, requirement: 100, isUnlocked: false, unlockedAt: nil),
        // Consistency
        Achievement(id: UUID(), title: "Week Warrior", description: "Practice every day for a week", icon: "calendar.badge.checkmark", type: .consistency, requirement: 7, isUnlocked: false, unlockedAt: nil),
        Achievement(id: UUID(), title: "Month Master", description: "Practice every day for a month", icon: "crown.fill", type: .consistency, requirement: 30, isUnlocked: false, unlockedAt: nil)
    ]

    private init() {
        loadAchievements()
    }

    // MARK: - Achievement Checking

    func checkAchievements(streakDays: Int, totalHours: Double) {
        for achievement in AchievementService.predefinedAchievements {
            var updated = achievement

            switch achievement.type {
            case .streak:
                if streakDays >= achievement.requirement && !unlockedAchievements.contains(achievement.id) {
                    updated.isUnlocked = true
                    updated.unlockedAt = Date()
                    unlockedAchievements.insert(achievement.id)
                    triggerHaptic()
                }
            case .totalHours:
                if Int(totalHours) >= achievement.requirement && !unlockedAchievements.contains(achievement.id) {
                    updated.isUnlocked = true
                    updated.unlockedAt = Date()
                    unlockedAchievements.insert(achievement.id)
                    triggerHaptic()
                }
            default:
                break
            }
        }
        saveAchievements()
    }

    // MARK: - Custom Milestones

    func createMilestone(title: String, skillName: String?, targetDays: Int) {
        let milestone = CustomMilestone(
            id: UUID(),
            title: title,
            skillName: skillName,
            targetDays: targetDays,
            currentDays: 0
        )
        customMilestones.append(milestone)
        saveCustomMilestones()
    }

    func updateMilestoneProgress(_ milestone: CustomMilestone, days: Int) {
        if let index = customMilestones.firstIndex(where: { $0.id == milestone.id }) {
            customMilestones[index].currentDays = days
            if days >= milestone.targetDays {
                // Milestone completed!
                triggerHaptic()
            }
            saveCustomMilestones()
        }
    }

    // MARK: - Seasonal Challenges

    func generateSeasonalChallenges() -> [SeasonalChallenge] {
        let month = Calendar.current.component(.month, from: Date())
        let season: String
        switch month {
        case 3...5: season = "Spring"
        case 6...8: season = "Summer"
        case 9...11: season = "Fall"
        default: season = "Winter"
        }

        return [
            SeasonalChallenge(id: UUID(), title: "Practice \(season)", description: "Practice 5 different skills this \(season)", skillCount: 5, duration: 90),
            SeasonalChallenge(id: UUID(), title: "\(season) Streak", description: "Maintain a 14-day streak during \(season)", streakDays: 14, duration: 14),
            SeasonalChallenge(id: UUID(), title: "\(season) Champion", description: "Log 1000 minutes this \(season)", minutes: 1000, duration: 90)
        ]
    }

    struct SeasonalChallenge: Identifiable {
        let id: UUID
        let title: String
        let description: String
        var skillCount: Int?
        var streakDays: Int?
        var minutes: Int?
        let duration: Int
    }

    // MARK: - Persistence

    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let saved = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = saved
        } else {
            achievements = AchievementService.predefinedAchievements
        }

        if let ids = UserDefaults.standard.array(forKey: "unlockedAchievements") as? [String] {
            unlockedAchievements = Set(ids.compactMap { UUID(uuidString: $0) })
        }

        if let data = UserDefaults.standard.data(forKey: "customMilestones"),
           let milestones = try? JSONDecoder().decode([CustomMilestone].self, from: data) {
            customMilestones = milestones
        }
    }

    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: "achievements")
        }
        UserDefaults.standard.set(Array(unlockedAchievements.map { $0.uuidString }), forKey: "unlockedAchievements")
    }

    private func saveCustomMilestones() {
        if let data = try? JSONEncoder().encode(customMilestones) {
            UserDefaults.standard.set(data, forKey: "customMilestones")
        }
    }

    private func triggerHaptic() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
}
