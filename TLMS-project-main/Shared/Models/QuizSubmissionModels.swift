//
//  QuizSubmissionModels.swift
//  TLMS-project-main
//
//  Models for Quiz Submissions and Results Analytics
//

import SwiftUI
import Foundation

// MARK: - Submission Status

enum SubmissionStatus: String, Codable, CaseIterable {
    case submitted = "submitted"
    case graded = "graded"
    case pendingReview = "pending_review"
    
    var displayName: String {
        switch self {
        case .submitted: return "Submitted"
        case .graded: return "Graded"
        case .pendingReview: return "Pending Review"
        }
    }
    
    var icon: String {
        switch self {
        case .submitted: return "checkmark.circle.fill"
        case .graded: return "checkmark.seal.fill"
        case .pendingReview: return "clock.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .submitted: return .blue
        case .graded: return .green
        case .pendingReview: return .orange
        }
    }
}

// MARK: - Quiz Answer

struct QuizAnswer: Codable, Identifiable {
    var id: UUID
    var questionID: UUID
    var selectedOptionIndices: [Int]  // For MCQ
    var textAnswer: String?  // For descriptive
    var isCorrect: Bool?
    var pointsEarned: Int
    var feedback: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case questionID = "question_id"
        case selectedOptionIndices = "selected_option_indices"
        case textAnswer = "text_answer"
        case isCorrect = "is_correct"
        case pointsEarned = "points_earned"
        case feedback
    }
    
    init(id: UUID = UUID(), questionID: UUID, selectedOptionIndices: [Int] = [], textAnswer: String? = nil, isCorrect: Bool? = nil, pointsEarned: Int = 0, feedback: String? = nil) {
        self.id = id
        self.questionID = questionID
        self.selectedOptionIndices = selectedOptionIndices
        self.textAnswer = textAnswer
        self.isCorrect = isCorrect
        self.pointsEarned = pointsEarned
        self.feedback = feedback
    }
}

// MARK: - Quiz Submission

struct QuizSubmission: Identifiable, Codable {
    var id: UUID
    var quizID: UUID
    var learnerID: UUID
    var learnerName: String?  // Denormalized for display
    var learnerEmail: String?  // Denormalized for display
    var answers: [QuizAnswer]
    var score: Int
    var totalPoints: Int
    var status: SubmissionStatus
    var submittedAt: Date
    var gradedAt: Date?
    var timeSpentSeconds: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case quizID = "quiz_id"
        case learnerID = "learner_id"
        case learnerName = "learner_name"
        case learnerEmail = "learner_email"
        case answers
        case score
        case totalPoints = "total_points"
        case status
        case submittedAt = "submitted_at"
        case gradedAt = "graded_at"
        case timeSpentSeconds = "time_spent_seconds"
    }
    
    init(id: UUID = UUID(), quizID: UUID, learnerID: UUID, learnerName: String? = nil, learnerEmail: String? = nil, answers: [QuizAnswer] = [], score: Int = 0, totalPoints: Int = 0, status: SubmissionStatus = .submitted, submittedAt: Date = Date(), gradedAt: Date? = nil, timeSpentSeconds: Int? = nil) {
        self.id = id
        self.quizID = quizID
        self.learnerID = learnerID
        self.learnerName = learnerName
        self.learnerEmail = learnerEmail
        self.answers = answers
        self.score = score
        self.totalPoints = totalPoints
        self.status = status
        self.submittedAt = submittedAt
        self.gradedAt = gradedAt
        self.timeSpentSeconds = timeSpentSeconds
    }
    
    // Custom decoding to handle answers being either [QuizAnswer] or String (JSONB)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        quizID = try container.decode(UUID.self, forKey: .quizID)
        learnerID = try container.decode(UUID.self, forKey: .learnerID)
        learnerName = try? container.decode(String.self, forKey: .learnerName)
        learnerEmail = try? container.decode(String.self, forKey: .learnerEmail)
        score = try container.decode(Int.self, forKey: .score)
        totalPoints = try container.decode(Int.self, forKey: .totalPoints)
        status = try container.decode(SubmissionStatus.self, forKey: .status)
        submittedAt = try container.decode(Date.self, forKey: .submittedAt)
        gradedAt = try? container.decode(Date.self, forKey: .gradedAt)
        timeSpentSeconds = try? container.decode(Int.self, forKey: .timeSpentSeconds)
        
        // Handle answers being either [QuizAnswer] or String (JSONB from Supabase)
        if let answersArray = try? container.decode([QuizAnswer].self, forKey: .answers) {
            answers = answersArray
        } else if let answersString = try? container.decode(String.self, forKey: .answers),
                  let data = answersString.data(using: .utf8),
                  let decodedAnswers = try? JSONDecoder().decode([QuizAnswer].self, from: data) {
            answers = decodedAnswers
        } else {
            answers = []
        }
    }
    
    var percentageScore: Double {
        guard totalPoints > 0 else { return 0 }
        return Double(score) / Double(totalPoints) * 100
    }
    
    var grade: String {
        let percentage = percentageScore
        switch percentage {
        case 90...100: return "A+"
        case 80..<90: return "A"
        case 70..<80: return "B"
        case 60..<70: return "C"
        case 50..<60: return "D"
        default: return "F"
        }
    }
    
    var gradeColor: Color {
        let percentage = percentageScore
        switch percentage {
        case 80...100: return AppTheme.successGreen
        case 60..<80: return AppTheme.warningOrange
        default: return AppTheme.errorRed
        }
    }
}

// MARK: - Question Analytics

struct QuestionAnalytics: Identifiable {
    let id: UUID
    let questionText: String
    let questionType: QuestionType
    let totalAttempts: Int
    let correctAttempts: Int
    let averagePoints: Double
    let maxPoints: Int
    let commonWrongAnswers: [(option: String, count: Int)]
    
    var successRate: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctAttempts) / Double(totalAttempts) * 100
    }
    
    var difficulty: String {
        let rate = successRate
        switch rate {
        case 80...100: return "Easy"
        case 50..<80: return "Medium"
        default: return "Hard"
        }
    }
    
    var difficultyColor: Color {
        let rate = successRate
        switch rate {
        case 80...100: return AppTheme.successGreen
        case 50..<80: return AppTheme.warningOrange
        default: return AppTheme.errorRed
        }
    }
}

// MARK: - Quiz Analytics

struct QuizAnalytics: Identifiable {
    let id: UUID
    let quizID: UUID
    let quizTitle: String
    let totalSubmissions: Int
    let averageScore: Double
    let averagePercentage: Double
    let highestScore: Int
    let lowestScore: Int
    let totalPoints: Int
    let completionRate: Double
    let averageTimeSeconds: Int?
    let questionAnalytics: [QuestionAnalytics]
    
    var scoreDistribution: [ScoreRange] {
        // This will be calculated from submissions
        []
    }
    
    struct ScoreRange: Identifiable {
        let id = UUID()
        let range: String
        let count: Int
        let color: Color
    }
}

// MARK: - Learner Performance

struct LearnerPerformance: Identifiable {
    let id: UUID
    let learnerID: UUID
    let learnerName: String
    let learnerEmail: String
    let submission: QuizSubmission
    let rank: Int?
    let questionsCorrect: Int
    let questionsTotal: Int
    
    var accuracyRate: Double {
        guard questionsTotal > 0 else { return 0 }
        return Double(questionsCorrect) / Double(questionsTotal) * 100
    }
}

// MARK: - Quiz Results Summary (for list view)

struct QuizResultsSummary: Identifiable {
    let id: UUID
    let quizID: UUID
    let quizTitle: String
    let courseTitle: String
    let totalSubmissions: Int
    let averageScore: Double
    let totalPoints: Int
    let lastSubmissionDate: Date?
    let needsGrading: Int  // Count of submissions pending manual grading
    
    var averagePercentage: Double {
        guard totalPoints > 0 else { return 0 }
        return (averageScore / Double(totalPoints)) * 100
    }
    
    var performanceColor: Color {
        let percentage = averagePercentage
        switch percentage {
        case 80...100: return AppTheme.successGreen
        case 60..<80: return AppTheme.warningOrange
        default: return AppTheme.errorRed
        }
    }
}
