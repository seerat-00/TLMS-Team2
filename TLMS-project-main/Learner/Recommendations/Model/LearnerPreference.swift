import Foundation

struct LearnerPreference: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let interests: [String]
    let skillLevel: String
    let goals: [String]
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case interests
        case skillLevel = "skill_level"
        case goals
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
