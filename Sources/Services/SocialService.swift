import Foundation
import SwiftUI

// R11: Social Features for Graft
// Anonymous practice sharing, buddy matching, leaderboards
@MainActor
final class SocialService: ObservableObject {
    static let shared = SocialService()

    @Published var sharedStreaks: [SharedStreak] = []
    @Published var buddyMatches: [BuddyMatch] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var isLoading = false

    struct SharedStreak: Identifiable, Codable {
        let id: UUID
        let skillName: String
        let streakDays: Int
        let username: String
        let sharedAt: Date
    }

    struct BuddyMatch: Identifiable {
        let id: UUID
        let username: String
        let skills: [String]
        let goalMinutesPerWeek: Int
        let matchScore: Double
    }

    struct LeaderboardEntry: Identifiable {
        let id: UUID
        let rank: Int
        let username: String
        let weeklyMinutes: Int
        let isAnonymous: Bool
    }

    private init() {
        loadSharedStreaks()
    }

    // MARK: - Anonymous Sharing

    func shareStreak(skillName: String, streakDays: Int) {
        let streak = SharedStreak(
            id: UUID(),
            skillName: skillName,
            streakDays: streakDays,
            username: "Anonymous",
            sharedAt: Date()
        )
        sharedStreaks.insert(streak, at: 0)
        saveSharedStreaks()
    }

    // MARK: - Buddy Matching

    func findBuddies(mySkills: [String], myGoalMinutes: Int) {
        // Simple matching based on shared skills
        // In a real app, this would query a backend
        let mockBuddies = [
            BuddyMatch(id: UUID(), username: "Alex", skills: ["Guitar", "Piano"], goalMinutesPerWeek: 180, matchScore: 0.85),
            BuddyMatch(id: UUID(), username: "Sam", skills: ["Guitar", "Drums"], goalMinutesPerWeek: 120, matchScore: 0.72)
        ]
        buddyMatches = mockBuddies.filter { buddy in
            !Set(buddy.skills).isDisjoint(with: Set(mySkills))
        }
    }

    // MARK: - Leaderboard

    func fetchLeaderboard() {
        // Mock leaderboard data
        leaderboard = [
            LeaderboardEntry(id: UUID(), rank: 1, username: "MusicMaster", weeklyMinutes: 320, isAnonymous: false),
            LeaderboardEntry(id: UUID(), rank: 2, username: "Anonymous", weeklyMinutes: 285, isAnonymous: true),
            LeaderboardEntry(id: UUID(), rank: 3, username: "PracticePro", weeklyMinutes: 240, isAnonymous: false),
            LeaderboardEntry(id: UUID(), rank: 4, username: "Anonymous", weeklyMinutes: 210, isAnonymous: true),
            LeaderboardEntry(id: UUID(), rank: 5, username: "ChordKing", weeklyMinutes: 195, isAnonymous: false)
        ]
    }

    // MARK: - Team Challenges

    func createTeamChallenge(title: String, goalMinutes: Int, duration: Int) -> TeamChallenge {
        TeamChallenge(
            id: UUID(),
            title: title,
            goalMinutes: goalMinutes,
            durationDays: duration,
            members: [],
            progress: 0,
            createdAt: Date()
        )
    }

    struct TeamChallenge: Identifiable {
        let id: UUID
        let title: String
        let goalMinutes: Int
        let durationDays: Int
        var members: [String]
        var progress: Int
        let createdAt: Date
    }

    // MARK: - Persistence

    private func loadSharedStreaks() {
        guard let data = UserDefaults.standard.data(forKey: "sharedStreaks"),
              let streaks = try? JSONDecoder().decode([SharedStreak].self, from: data) else {
            return
        }
        sharedStreaks = streaks
    }

    private func saveSharedStreaks() {
        guard let data = try? JSONEncoder().encode(sharedStreaks) else { return }
        UserDefaults.standard.set(data, forKey: "sharedStreaks")
    }
}
