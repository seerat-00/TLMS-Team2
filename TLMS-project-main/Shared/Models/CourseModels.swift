//
//  CourseModels.swift
//  TLMS-project-main
//
//  Models for Course, Module, and Lesson
//

import Foundation

struct Course: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var category: String
    var educatorID: UUID
    var modules: [Module] = []
    var isPublished: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
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
