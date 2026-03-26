import Foundation

// MARK: - Graft R12-R20: Social Fitness, Challenges, Leaderboards

// MARK: R12: Community, Leaderboards, Shared Challenges

struct SharedChallenge: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var challengeType: ChallengeType
    var description: String
    var participantIDs: [String]
    var startDate: Date
    var endDate: Date
    var goal: ChallengeGoal
    var status: Status
    var leaderboard: [LeaderboardEntry]
    
    enum ChallengeType: String, Codable {
        case steps = "Steps"
        case distance = "Distance"
        case workout = "Workouts"
        case streak = "Streak"
        case custom = "Custom"
    }
    
    struct ChallengeGoal: Codable, Equatable {
        var targetValue: Double
        var unit: String
        var isTeamGoal: Bool
        
        init(targetValue: Double = 0, unit: String = "steps", isTeamGoal: Bool = false) {
            self.targetValue = targetValue
            self.unit = unit
            self.isTeamGoal = isTeamGoal
        }
    }
    
    struct LeaderboardEntry: Identifiable, Codable, Equatable {
        let id: UUID
        var userID: String
        var displayName: String
        var avatarURL: String?
        var currentValue: Double
        var rank: Int
        var trend: Trend // +1, -1, 0
        
        enum Trend: Int, Codable {
            case up = 1, down = -1, same = 0
        }
        
        init(id: UUID = UUID(), userID: String, displayName: String, avatarURL: String? = nil, currentValue: Double = 0, rank: Int = 0, trend: Trend = .same) {
            self.id = id
            self.userID = userID
            self.displayName = displayName
            self.avatarURL = avatarURL
            self.currentValue = currentValue
            self.rank = rank
            self.trend = trend
        }
    }
    
    enum Status: String, Codable {
        case upcoming, active, completed, cancelled
    }
    
    init(id: UUID = UUID(), name: String, challengeType: ChallengeType, description: String = "", participantIDs: [String] = [], startDate: Date, endDate: Date, goal: ChallengeGoal = ChallengeGoal(), status: Status = .upcoming, leaderboard: [LeaderboardEntry] = []) {
        self.id = id
        self.name = name
        self.challengeType = challengeType
        self.description = description
        self.participantIDs = participantIDs
        self.startDate = startDate
        self.endDate = endDate
        self.goal = goal
        self.status = status
        self.leaderboard = leaderboard
    }
}

struct TeamOrSquad: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var memberIDs: [String]
    var captainID: String
    var totalPoints: Int
    var createdAt: Date
    var isPublic: Bool
    
    init(id: UUID = UUID(), name: String, memberIDs: [String] = [], captainID: String, totalPoints: Int = 0, createdAt: Date = Date(), isPublic: Bool = false) {
        self.id = id
        self.name = name
        self.memberIDs = memberIDs
        self.captainID = captainID
        self.totalPoints = totalPoints
        self.createdAt = createdAt
        self.isPublic = isPublic
    }
}

// MARK: R13: Graft Pro, Coaching, Advanced Analytics

struct CoachingProgram: Identifiable, Codable, Equatable {
    let id: UUID
    var coachUserID: String
    var athleteUserID: String
    var programType: ProgramType
    var durationWeeks: Int
    var weeklyPlan: [WeeklyPlan]
    var isActive: Bool
    var createdAt: Date
    
    enum ProgramType: String, Codable {
        case strength = "Strength"
        case endurance = "Endurance"
        case weightLoss = "Weight Loss"
        case mobility = "Mobility"
        case custom = "Custom"
    }
    
    struct WeeklyPlan: Identifiable, Codable, Equatable {
        let id: UUID
        var weekNumber: Int
        var workouts: [Workout]
        
        init(id: UUID = UUID(), weekNumber: Int, workouts: [Workout] = []) {
            self.id = id
            self.weekNumber = weekNumber
            self.workouts = workouts
        }
    }
    
    struct Workout: Identifiable, Codable, Equatable {
        let id: UUID
        var name: String
        var exercises: [String]
        var targetDuration: TimeInterval
        var isCompleted: Bool
        
        init(id: UUID = UUID(), name: String, exercises: [String] = [], targetDuration: TimeInterval = 0, isCompleted: Bool = false) {
            self.id = id
            self.name = name
            self.exercises = exercises
            self.targetDuration = targetDuration
            self.isCompleted = isCompleted
        }
    }
    
    init(id: UUID = UUID(), coachUserID: String, athleteUserID: String, programType: ProgramType, durationWeeks: Int = 12, weeklyPlan: [WeeklyPlan] = [], isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.coachUserID = coachUserID
        self.athleteUserID = athleteUserID
        self.programType = programType
        self.durationWeeks = durationWeeks
        self.weeklyPlan = weeklyPlan
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

// MARK: R14: Wearable Ecosystem, Device Integrations

struct WearableIntegration: Identifiable, Codable, Equatable {
    let id: UUID
    var deviceName: String
    var deviceType: DeviceType
    var isConnected: Bool
    var lastSyncAt: Date?
    
    enum DeviceType: String, Codable {
        case appleWatch = "Apple Watch"
        case garmin = "Garmin"
        case fitbit = "Fitbit"
        case whoop = "Whoop"
        case samsungGalaxy = "Samsung Galaxy Watch"
        case peloton = "Peloton"
        case concept2 = "Concept2 Rower"
    }
    
    init(id: UUID = UUID(), deviceName: String, deviceType: DeviceType, isConnected: Bool = false, lastSyncAt: Date? = nil) {
        self.id = id
        self.deviceName = deviceName
        self.deviceType = deviceType
        self.isConnected = isConnected
        self.lastSyncAt = lastSyncAt
    }
}

// MARK: R15: Subscription Business

struct GraftSubscriptionTier: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var displayName: String
    var monthlyPrice: Decimal
    var annualPrice: Decimal
    var lifetimePrice: Decimal
    var features: [String]
    var isMostPopular: Bool
    
    static let free = GraftSubscriptionTier(id: UUID(), name: "free", displayName: "Free", monthlyPrice: 0, annualPrice: 0, lifetimePrice: 0, features: ["Basic tracking", "Simple challenges", "3 leaderboards"], isMostPopular: false)
    static let pro = GraftSubscriptionTier(id: UUID(), name: "pro", displayName: "Pro", monthlyPrice: 9.99, annualPrice: 95.88, lifetimePrice: 199, features: ["Unlimited challenges", "Coaching", "Advanced analytics", "All devices"], isMostPopular: true)
    static let elite = GraftSubscriptionTier(id: UUID(), name: "elite", displayName: "Elite", monthlyPrice: 14.99, annualPrice: 143.88, lifetimePrice: 0, features: ["Personal coaching", "Team management", "Race planning", "Priority support"], isMostPopular: false)
}

// MARK: R16: i18n, International, Cultural Adaptation

struct SupportedLocale: Identifiable, Codable, Equatable {
    let id: UUID
    var code: String
    var displayName: String
    var nativeName: String
    
    static let supported: [SupportedLocale] = [
        SupportedLocale(id: UUID(), code: "en", displayName: "English", nativeName: "English"),
        SupportedLocale(id: UUID(), code: "de", displayName: "German", nativeName: "Deutsch"),
        SupportedLocale(id: UUID(), code: "fr", displayName: "French", nativeName: "Français"),
        SupportedLocale(id: UUID(), code: "es", displayName: "Spanish", nativeName: "Español"),
        SupportedLocale(id: UUID(), code: "ja", displayName: "Japanese", nativeName: "日本語"),
    ]
}

// MARK: R17: Android, Cross-Platform

struct CrossPlatformDevice: Identifiable, Codable, Equatable {
    let id: UUID
    var deviceName: String
    var platform: Platform
    var lastSyncAt: Date
    
    enum Platform: String, Codable {
        case ios, android, web
    }
    
    init(id: UUID = UUID(), deviceName: String, platform: Platform, lastSyncAt: Date = Date()) {
        self.id = id
        self.deviceName = deviceName
        self.platform = platform
        self.lastSyncAt = lastSyncAt
    }
}

// MARK: R18: Team Building, Architecture

struct TeamMember: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var role: String
    var email: String
    
    init(id: UUID = UUID(), name: String, role: String, email: String) {
        self.id = id
        self.name = name
        self.role = role
        self.email = email
    }
}

// MARK: R19: Awards, Press

struct AwardSubmission: Identifiable, Codable, Equatable {
    let id: UUID
    var awardName: String
    var category: String
    var status: Status
    var submittedAt: Date
    
    enum Status: String, Codable {
        case draft, submitted, inReview, won, rejected
    }
    
    init(id: UUID = UUID(), awardName: String, category: String, status: Status = .draft, submittedAt: Date = Date()) {
        self.id = id
        self.awardName = awardName
        self.category = category
        self.status = status
        self.submittedAt = submittedAt
    }
}

// MARK: R20: Platform Ecosystem, SDK, Vision

struct PlatformIntegration: Identifiable, Codable, Equatable {
    let id: UUID
    var platform: String
    var isEnabled: Bool
    
    init(id: UUID = UUID(), platform: String, isEnabled: Bool = false) {
        self.id = id
        self.platform = platform
        self.isEnabled = isEnabled
    }
}

struct GraftAPI: Codable, Equatable {
    var clientID: String
    var accessToken: String?
    var tier: APITier
    
    enum APITier: String, Codable {
        case free = "Free"
        case paid = "Paid"
    }
    
    init(clientID: String = UUID().uuidString, accessToken: String? = nil, tier: APITier = .free) {
        self.clientID = clientID
        self.accessToken = accessToken
        self.tier = tier
    }
}
