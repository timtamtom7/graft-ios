import Foundation
import Combine

/// Graft R12-R20 Service
final class GraftR12R20Service: ObservableObject, @unchecked Sendable {
    static let shared = GraftR12R20Service()
    
    @Published var challenges: [SharedChallenge] = []
    @Published var teams: [TeamOrSquad] = []
    @Published var coachingPrograms: [CoachingProgram] = []
    @Published var wearableIntegrations: [WearableIntegration] = []
    @Published var currentTier: GraftSubscriptionTier = .free
    @Published var crossPlatformDevices: [CrossPlatformDevice] = []
    @Published var awardSubmissions: [AwardSubmission] = []
    @Published var apiCredentials: GraftAPI?
    
    private let userDefaults = UserDefaults.standard
    
    private init() { loadFromDisk() }
    
    func createChallenge(name: String, type: SharedChallenge.ChallengeType, goal: SharedChallenge.ChallengeGoal, startDate: Date, endDate: Date) -> SharedChallenge {
        let challenge = SharedChallenge(name: name, challengeType: type, participantIDs: [], startDate: startDate, endDate: endDate, goal: goal)
        challenges.append(challenge)
        saveToDisk()
        return challenge
    }
    
    func joinChallenge(_ challengeID: UUID, userID: String) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeID }) else { return }
        if !challenges[index].participantIDs.contains(userID) {
            challenges[index].participantIDs.append(userID)
        }
        saveToDisk()
    }
    
    func updateLeaderboard(_ challengeID: UUID, entries: [SharedChallenge.LeaderboardEntry]) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeID }) else { return }
        challenges[index].leaderboard = entries.sorted { $0.rank < $1.rank }
        saveToDisk()
    }
    
    func createTeam(name: String, captainID: String) -> TeamOrSquad {
        let team = TeamOrSquad(name: name, captainID: captainID)
        teams.append(team)
        saveToDisk()
        return team
    }
    
    func createCoachingProgram(coachID: String, athleteID: String, type: CoachingProgram.ProgramType) -> CoachingProgram {
        let program = CoachingProgram(coachUserID: coachID, athleteUserID: athleteID, programType: type)
        coachingPrograms.append(program)
        saveToDisk()
        return program
    }
    
    func connectWearable(name: String, type: WearableIntegration.DeviceType) -> WearableIntegration {
        let wearable = WearableIntegration(deviceName: name, deviceType: type, isConnected: true, lastSyncAt: Date())
        wearableIntegrations.append(wearable)
        saveToDisk()
        return wearable
    }
    
    func subscribe(to tier: GraftSubscriptionTier) async -> Bool {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            currentTier = tier
            saveToDisk()
        }
        return true
    }
    
    func registerDevice(name: String, platform: CrossPlatformDevice.Platform) -> CrossPlatformDevice {
        let device = CrossPlatformDevice(deviceName: name, platform: platform)
        crossPlatformDevices.append(device)
        saveToDisk()
        return device
    }
    
    func submitAward(name: String, category: String) -> AwardSubmission {
        let award = AwardSubmission(awardName: name, category: category)
        awardSubmissions.append(award)
        saveToDisk()
        return award
    }
    
    func registerAPI(tier: GraftAPI.APITier) -> GraftAPI {
        let api = GraftAPI(tier: tier)
        apiCredentials = api
        saveToDisk()
        return api
    }
    
    private func saveToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(challenges) { userDefaults.set(data, forKey: "graft_challenges") }
        if let data = try? encoder.encode(teams) { userDefaults.set(data, forKey: "graft_teams") }
        if let data = try? encoder.encode(coachingPrograms) { userDefaults.set(data, forKey: "graft_coaching") }
        if let data = try? encoder.encode(wearableIntegrations) { userDefaults.set(data, forKey: "graft_wearables") }
        if let data = try? encoder.encode(crossPlatformDevices) { userDefaults.set(data, forKey: "graft_devices") }
        if let data = try? encoder.encode(awardSubmissions) { userDefaults.set(data, forKey: "graft_awards") }
    }
    
    private func loadFromDisk() {
        let decoder = JSONDecoder()
        if let data = userDefaults.data(forKey: "graft_challenges"),
           let decoded = try? decoder.decode([SharedChallenge].self, from: data) { challenges = decoded }
        if let data = userDefaults.data(forKey: "graft_teams"),
           let decoded = try? decoder.decode([TeamOrSquad].self, from: data) { teams = decoded }
        if let data = userDefaults.data(forKey: "graft_coaching"),
           let decoded = try? decoder.decode([CoachingProgram].self, from: data) { coachingPrograms = decoded }
        if let data = userDefaults.data(forKey: "graft_wearables"),
           let decoded = try? decoder.decode([WearableIntegration].self, from: data) { wearableIntegrations = decoded }
        if let data = userDefaults.data(forKey: "graft_devices"),
           let decoded = try? decoder.decode([CrossPlatformDevice].self, from: data) { crossPlatformDevices = decoded }
        if let data = userDefaults.data(forKey: "graft_awards"),
           let decoded = try? decoder.decode([AwardSubmission].self, from: data) { awardSubmissions = decoded }
    }
}
