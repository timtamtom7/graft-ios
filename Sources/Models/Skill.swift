import Foundation

struct Skill: Identifiable, Equatable {
    var id: Int64?
    var name: String
    var emoji: String
    var isActive: Bool
    var createdAt: Date

    init(id: Int64? = nil, name: String, emoji: String, isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
