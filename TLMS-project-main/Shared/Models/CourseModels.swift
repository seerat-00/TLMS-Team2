//
//  CourseModels.swift
//  TLMS-project-main
//
//  Models for Course, Module, and Lesson
//

import SwiftUI
import Foundation

enum CourseStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case pendingReview = "pending_review"
    case published = "published"
    case rejected = "rejected"
    case removed = "removed"
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .pendingReview: return "Pending Review"
        case .published: return "Published"
        case .rejected: return "Rejected"
        case .removed: return "Removed"
        }
    }
    
    var icon: String {
        switch self {
        case .draft: return "doc.text.fill"
        case .pendingReview: return "clock.fill"
        case .published: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .removed: return "trash.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .draft: return .gray
        case .pendingReview: return .orange
        case .published: return .green
        case .rejected: return .red
        case .removed: return .red
        }
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

struct Course: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var category: String
    var educatorID: UUID
    var modules: [Module] = []
    var status: CourseStatus = .draft
    var courseCoverUrl: String?
    var level: CourseLevel = .beginner
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var enrollmentCount: Int = 0
    var rating: Double?
    var price: Double?
    var enrolledCount: Int?
    
    // Convenience property for backward compatibility
    var thumbnailUrl: String? {
        get { courseCoverUrl }
        set { courseCoverUrl = newValue }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case educatorID = "educator_id"
        case modules
        case status
        case courseCoverUrl = "course_cover_url"
        case level
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case enrollmentCount = "enrollment_count"
        case rating
        case price
        case enrolledCount = "enrolled_count"
    }
    
    // Default init
    init(id: UUID = UUID(), title: String, description: String, category: String, educatorID: UUID, modules: [Module] = [], status: CourseStatus = .draft, courseCoverUrl: String? = nil, level: CourseLevel = .beginner, createdAt: Date = Date(), updatedAt: Date = Date(), enrollmentCount: Int = 0, rating: Double? = nil, price: Double? = nil, enrolledCount: Int? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.educatorID = educatorID
        self.modules = modules
        self.status = status
        self.courseCoverUrl = courseCoverUrl
        self.level = level
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.enrollmentCount = enrollmentCount
        self.rating = rating
        self.price = price
        self.enrolledCount = enrolledCount
    }
    
    // Custom decoding to handle both JSON array and JSON string for modules
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(String.self, forKey: .category)
        educatorID = try container.decode(UUID.self, forKey: .educatorID)
        status = try container.decode(CourseStatus.self, forKey: .status)
        courseCoverUrl = try container.decodeIfPresent(String.self, forKey: .courseCoverUrl)
        level = try container.decodeIfPresent(CourseLevel.self, forKey: .level) ?? .beginner
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        enrollmentCount = try container.decodeIfPresent(Int.self, forKey: .enrollmentCount) ?? 0
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        enrolledCount = try container.decodeIfPresent(Int.self, forKey: .enrolledCount)
        
        // Handle modules being either [Module] or String
        if let modulesArray = try? container.decode([Module].self, forKey: .modules) {
            modules = modulesArray
        } else if let modulesString = try? container.decode(String.self, forKey: .modules),
                  let data = modulesString.data(using: .utf8),
                  let decodedModules = try? JSONDecoder().decode([Module].self, from: data) {
            modules = decodedModules
        } else {
            modules = []
        }
    }
    
    // MARK: - Helper Properties
    
    var categoryIcon: String {
        switch category {
        case "Programming":
            return "chevron.left.forwardslash.chevron.right"
        case "Design":
            return "paintbrush.fill"
        case "Business":
            return "briefcase.fill"
        case "Marketing":
            return "megaphone.fill"
        case "Data Science":
            return "chart.bar.fill"
        case "Photography":
            return "camera.fill"
        case "Music":
            return "music.note"
        case "Health & Fitness":
            return "heart.fill"
        case "Language":
            return "text.bubble.fill"
        case "Personal Development":
            return "person.fill"
        default:
            return "book.fill"
        }
    }
    
    var categoryColor: Color {
        switch category {
        case "Programming":
            return Color(red: 0.2, green: 0.6, blue: 1.0)
        case "Design":
            return Color(red: 1.0, green: 0.4, blue: 0.6)
        case "Business":
            return Color(red: 0.4, green: 0.8, blue: 0.4)
        case "Marketing":
            return Color(red: 1.0, green: 0.6, blue: 0.2)
        case "Data Science":
            return Color(red: 0.6, green: 0.4, blue: 1.0)
        case "Photography":
            return Color(red: 1.0, green: 0.8, blue: 0.2)
        case "Music":
            return Color(red: 1.0, green: 0.3, blue: 0.5)
        case "Health & Fitness":
            return Color(red: 0.2, green: 0.8, blue: 0.6)
        case "Language":
            return Color(red: 0.5, green: 0.7, blue: 1.0)
        case "Personal Development":
            return Color(red: 0.8, green: 0.5, blue: 1.0)
        default:
            return Color(red: 0.0, green: 86.0/255.0, blue: 210.0/255.0)
        }
    }
}

struct Module: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String?
    var lessons: [Lesson] = []
    
    // Helper to ensure name is not empty string when saving, though UI should enforce it
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct Lesson: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var content: String? // URL or text content depending on type
    var type: ContentType
    var duration: TimeInterval?
    var quizQuestions: [Question]? // Quiz questions when type is .quiz
    
    // Helper to ensure name is not empty
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Validate quiz lessons have questions
    var isQuizValid: Bool {
        guard type == .quiz else { return true }
        guard let questions = quizQuestions, !questions.isEmpty else { return false }
        return questions.allSatisfy { $0.isValid }
    }
}

enum ContentType: String, Codable, CaseIterable, Identifiable {
    case video = "Video"
    case pdf = "PDF"
    case text = "Text"
    case presentation = "Presentation"
    case quiz = "Quiz"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .video: return "play.rectangle.fill"
        case .pdf: return "doc.fill"
        case .text: return "doc.text.fill"
        case .presentation: return "rectangle.on.rectangle.fill"
        case .quiz: return "checkmark.circle.fill"
        }
    }
}
