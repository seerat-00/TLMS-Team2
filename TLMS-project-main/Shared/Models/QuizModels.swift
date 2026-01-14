//
//  QuizModels.swift
//  TLMS-project-main
//
//  Models for Quiz and Question
//

import SwiftUI
import Foundation

enum QuizStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case published = "published"
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .published: return "Published"
        }
    }
    
    var icon: String {
        switch self {
        case .draft: return "doc.text.fill"
        case .published: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .draft: return .gray
        case .published: return .green
        }
    }
}

enum QuestionType: String, Codable, CaseIterable, Identifiable {
    case singleChoice = "Single Choice"
    case multipleChoice = "Multiple Choice"
    case descriptive = "Descriptive"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .singleChoice: return "Single Choice"
        case .multipleChoice: return "Multiple Choice"
        case .descriptive: return "Descriptive"
        }
    }
    
    var icon: String {
        switch self {
        case .singleChoice: return "circle.circle"
        case .multipleChoice: return "checkmark.square"
        case .descriptive: return "text.alignleft"
        }
    }
    
    var description: String {
        switch self {
        case .singleChoice: return "One correct answer"
        case .multipleChoice: return "Multiple correct answers"
        case .descriptive: return "Text-based answer"
        }
    }
}

struct Question: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var options: [String]
    var correctAnswerIndices: [Int]  // Changed to array to support multiple correct answers
    var points: Int
    var explanation: String?
    var type: QuestionType
    var requiresManualGrading: Bool
    
    // Computed property for character limit based on points (100 chars per point)
    var characterLimit: Int {
        return points * 100
    }
    
    init(id: UUID = UUID(), text: String = "", options: [String] = ["", "", "", ""], correctAnswerIndices: [Int] = [0], points: Int = 1, explanation: String? = nil, type: QuestionType = .singleChoice, requiresManualGrading: Bool = false) {
        self.id = id
        self.text = text
        self.options = options
        self.correctAnswerIndices = correctAnswerIndices
        self.points = points
        self.explanation = explanation
        self.type = type
        self.requiresManualGrading = requiresManualGrading
    }
    
    var isValid: Bool {
        // Question text must not be empty
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        
        // Points must be positive
        guard points > 0 else { return false }
        
        // Type-specific validation
        switch type {
        case .singleChoice, .multipleChoice:
            // All options must be filled
            guard options.count == 4 else { return false }
            for option in options {
                if option.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return false
                }
            }
            
            // At least one correct answer must be selected
            guard !correctAnswerIndices.isEmpty else { return false }
            
            // All correct answer indices must be valid
            for index in correctAnswerIndices {
                guard index >= 0 && index < options.count else { return false }
            }
            
            // Single choice should have exactly one correct answer
            if type == .singleChoice {
                guard correctAnswerIndices.count == 1 else { return false }
            }
            
        case .descriptive:
            // Descriptive questions don't need options, just question text
            // Character limit is automatically calculated based on points
            break
        }
        
        return true
    }
}

struct Quiz: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var courseID: UUID
    var educatorID: UUID
    var questions: [Question]
    var status: QuizStatus
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case courseID = "course_id"
        case educatorID = "educator_id"
        case questions
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), title: String, courseID: UUID, educatorID: UUID, questions: [Question] = [], status: QuizStatus = .draft, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.courseID = courseID
        self.educatorID = educatorID
        self.questions = questions
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Custom decoding to handle questions being either [Question] or String
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        courseID = try container.decode(UUID.self, forKey: .courseID)
        educatorID = try container.decode(UUID.self, forKey: .educatorID)
        status = try container.decode(QuizStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Handle questions being either [Question] or String (JSONB from Supabase)
        if let questionsArray = try? container.decode([Question].self, forKey: .questions) {
            questions = questionsArray
        } else if let questionsString = try? container.decode(String.self, forKey: .questions),
                  let data = questionsString.data(using: .utf8),
                  let decodedQuestions = try? JSONDecoder().decode([Question].self, from: data) {
            questions = decodedQuestions
        } else {
            questions = []
        }
    }
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var totalPoints: Int {
        questions.reduce(0) { $0 + $1.points }
    }
    
    var questionCount: Int {
        questions.count
    }
}
