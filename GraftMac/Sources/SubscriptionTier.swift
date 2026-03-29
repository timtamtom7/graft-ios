// Stub types needed by DatabaseService on macOS
// The full SubscriptionTier enum lives in Sources/Views/PricingView.swift (iOS only)

enum SubscriptionTier: String, CaseIterable, Codable {
    case free = "free"
    case track = "track"
    case pro = "pro"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .track: return "Track"
        case .pro: return "Pro"
        }
    }
}
