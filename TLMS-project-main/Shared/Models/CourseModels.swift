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
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .pendingReview: return "Pending Review"
        case .published: return "Published"
        case .rejected: return "Rejected"
        }
    }
    
    var icon: String {
        switch self {
        case .draft: return "doc.text.fill"
        case .pendingReview: return "clock.fill"
        case .published: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .draft: return .gray
        case .pendingReview: return .orange
        case .published: return .green
        case .rejected: return .red
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
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case educatorID = "educator_id"
        case modules
        case status
        case courseCoverUrl = "course_cover_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Default init
    init(id: UUID = UUID(), title: String, description: String, category: String, educatorID: UUID, modules: [Module] = [], status: CourseStatus = .draft, courseCoverUrl: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.educatorID = educatorID
        self.modules = modules
        self.status = status
        self.courseCoverUrl = courseCoverUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
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
    
    // Helper to ensure name is not empty
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
