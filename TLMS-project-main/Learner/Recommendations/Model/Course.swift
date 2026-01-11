import Foundation

struct Course: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String?
    let thumbnailUrl: String?
    let category: String?
    let level: CourseLevel
    let educatorId: UUID
    let createdAt: Date
    let status: String? // "published", "draft"
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case thumbnailUrl = "thumbnail_url"
        case category
        case level
        case educatorId = "educator_id"
        case createdAt = "created_at"
        case status
    }
}

enum CourseLevel: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case allLevels = "All Levels"
    
    // Helper to match Supabase values which might be lowercase or snake_case
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        
        switch stringValue.lowercased().replacingOccurrences(of: "_", with: " ") {
        case "beginner": self = .beginner
        case "intermediate": self = .intermediate
        case "advanced": self = .advanced
        case "all levels", "all_levels": self = .allLevels
        default: self = .beginner // Fallback
        }
    }
}
