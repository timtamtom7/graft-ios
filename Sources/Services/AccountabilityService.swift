import Foundation

// MARK: - R12: Accountability Partners

enum PartnerStatus: String, Codable {
    case active = "Active"
    case inactive = "Inactive"
    case pending = "Pending"
}

struct AccountabilityPartner: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var skill: String
    var lastCheckIn: Date?
    var streak: Int
    var status: PartnerStatus

    init(id: UUID = UUID(), name: String, skill: String, lastCheckIn: Date? = nil, streak: Int = 0, status: PartnerStatus = .active) {
        self.id = id
        self.name = name
        self.skill = skill
        self.lastCheckIn = lastCheckIn
        self.streak = streak
        self.status = status
    }
}

// MARK: - Accountability Service

final class AccountabilityService: ObservableObject, @unchecked Sendable {
    static let shared = AccountabilityService()

    @Published private(set) var partners: [AccountabilityPartner] = []
    @Published private(set) var pendingInvites: [PendingInvite] = []

    private let userDefaults = UserDefaults.standard
    private let partnersKey = "accountability_partners"
    private let invitesKey = "accountability_pending_invites"

    struct PendingInvite: Identifiable, Codable {
        let id: UUID
        let code: String
        let skill: String
        let createdAt: Date
    }

    private init() {
        loadPartners()
    }

    // MARK: - Partner Management

    /// Simplified invite by email only (skill defaults to "General")
    func invitePartner(email: String) async throws {
        try await invitePartner(email: email, skill: "General")
    }

    func invitePartner(email: String, skill: String) async throws {
        // Mock: simulate network call
        try await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            let code = generateInviteCode()
            let invite = PendingInvite(id: UUID(), code: code, skill: skill, createdAt: Date())
            pendingInvites.append(invite)
            savePendingInvites()
        }
    }

    func acceptInvite(code: String) async throws -> AccountabilityPartner? {
        // Mock: simulate network call
        try await Task.sleep(nanoseconds: 500_000_000)

        return await MainActor.run {
            guard let invite = pendingInvites.first(where: { $0.code == code }) else {
                return nil
            }

            let partner = AccountabilityPartner(
                id: UUID(),
                name: "Partner (\(invite.skill))",
                skill: invite.skill,
                lastCheckIn: nil,
                streak: 0,
                status: .active
            )

            partners.append(partner)
            pendingInvites.removeAll { $0.id == invite.id }
            savePartners()
            savePendingInvites()

            return partner
        }
    }

    func getPartners() -> [AccountabilityPartner] {
        return partners
    }

    func removePartner(_ partnerId: UUID) {
        partners.removeAll { $0.id == partnerId }
        savePartners()
    }

    // MARK: - Check-ins

    func sendCheckIn(skillId: UUID, completed: Bool) {
        // Record check-in for all partners tracking this skill
        // In a real app, this would sync to a backend
        for index in partners.indices {
            if partners[index].skill == "Guitar" { // mock skill matching
                partners[index].lastCheckIn = Date()
                if completed {
                    partners[index].streak += 1
                }
            }
        }
        savePartners()
    }

    func checkInPartner(_ partnerId: UUID, completed: Bool) {
        guard let index = partners.firstIndex(where: { $0.id == partnerId }) else { return }
        partners[index].lastCheckIn = Date()
        if completed {
            partners[index].streak += 1
        } else {
            partners[index].streak = 0
        }
        partners[index].status = completed ? .active : .inactive
        savePartners()
    }

    // MARK: - Encouragement

    func sendEncouragement(to partnerId: UUID, emoji: String) {
        // Mock: log encouragement
        print("Encouragement \(emoji) sent to partner \(partnerId)")
    }

    // MARK: - Persistence

    private func loadPartners() {
        guard let data = userDefaults.data(forKey: partnersKey),
              let decoded = try? JSONDecoder().decode([AccountabilityPartner].self, from: data) else {
            return
        }
        partners = decoded
    }

    private func savePartners() {
        guard let data = try? JSONEncoder().encode(partners) else { return }
        userDefaults.set(data, forKey: partnersKey)
    }

    private func loadPendingInvites() {
        guard let data = userDefaults.data(forKey: invitesKey),
              let decoded = try? JSONDecoder().decode([PendingInvite].self, from: data) else {
            return
        }
        pendingInvites = decoded
    }

    private func savePendingInvites() {
        guard let data = try? JSONEncoder().encode(pendingInvites) else { return }
        userDefaults.set(data, forKey: invitesKey)
    }

    private func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
