//
//  QuizResultsService.swift
//  TLMS-project-main
//
//  Service for managing quiz results and submissions
//

import Foundation
import Supabase
import Combine

@MainActor
class QuizResultsService: ObservableObject {
    private let supabase: SupabaseClient
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        self.supabase = SupabaseManager.shared.client
    }
    
    // MARK: - Fetch Quiz Submissions
    
    func fetchQuizSubmissions(quizID: UUID) async -> [QuizSubmission] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let submissions: [QuizSubmission] = try await supabase
                .from("quiz_submissions")
                .select()
                .eq("quiz_id", value: quizID.uuidString)
                .order("submitted_at", ascending: false)
                .execute()
                .value
            return submissions
        } catch {
            errorMessage = "Failed to fetch quiz submissions: \(error.localizedDescription)"
            return []
        }
    }
    
    func fetchSubmissionsByLearner(learnerID: UUID) async -> [QuizSubmission] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let submissions: [QuizSubmission] = try await supabase
                .from("quiz_submissions")
                .select()
                .eq("learner_id", value: learnerID.uuidString)
                .order("submitted_at", ascending: false)
                .execute()
                .value
            return submissions
        } catch {
            errorMessage = "Failed to fetch learner submissions: \(error.localizedDescription)"
            return []
        }
    }
    
    func fetchSubmission(submissionID: UUID) async -> QuizSubmission? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let submissions: [QuizSubmission] = try await supabase
                .from("quiz_submissions")
                .select()
                .eq("id", value: submissionID.uuidString)
                .execute()
                .value
            return submissions.first
        } catch {
            errorMessage = "Failed to fetch submission: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Fetch Quiz Results for Educator
    
    func fetchEducatorQuizResults(educatorID: UUID) async -> [QuizResultsSummary] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // First, fetch all quizzes by educator
            let quizzes: [Quiz] = try await supabase
                .from("quizzes")
                .select()
                .eq("educator_id", value: educatorID.uuidString)
                .eq("status", value: QuizStatus.published.rawValue)
                .order("updated_at", ascending: false)
                .execute()
                .value
            
            // For each quiz, fetch submission statistics
            var summaries: [QuizResultsSummary] = []
            
            for quiz in quizzes {
                let submissions = await fetchQuizSubmissions(quizID: quiz.id)
                
                guard !submissions.isEmpty else { continue }
                
                let totalSubmissions = submissions.count
                let averageScore = submissions.reduce(0.0) { $0 + Double($1.score) } / Double(totalSubmissions)
                let lastSubmission = submissions.first?.submittedAt
                let needsGrading = submissions.filter { $0.status == .pendingReview }.count
                
                // Fetch course title
                let courseTitle = await fetchCourseTitle(courseID: quiz.courseID)
                
                let summary = QuizResultsSummary(
                    id: UUID(),
                    quizID: quiz.id,
                    quizTitle: quiz.title,
                    courseTitle: courseTitle,
                    totalSubmissions: totalSubmissions,
                    averageScore: averageScore,
                    totalPoints: quiz.totalPoints,
                    lastSubmissionDate: lastSubmission,
                    needsGrading: needsGrading
                )
                
                summaries.append(summary)
            }
            
            return summaries
        } catch {
            errorMessage = "Failed to fetch quiz results: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Calculate Analytics
    
    func calculateQuizAnalytics(quiz: Quiz, submissions: [QuizSubmission]) -> QuizAnalytics {
        guard !submissions.isEmpty else {
            return QuizAnalytics(
                id: UUID(),
                quizID: quiz.id,
                quizTitle: quiz.title,
                totalSubmissions: 0,
                averageScore: 0,
                averagePercentage: 0,
                highestScore: 0,
                lowestScore: 0,
                totalPoints: quiz.totalPoints,
                completionRate: 0,
                averageTimeSeconds: nil,
                questionAnalytics: []
            )
        }
        
        let totalSubmissions = submissions.count
        let scores = submissions.map { $0.score }
        let averageScore = Double(scores.reduce(0, +)) / Double(totalSubmissions)
        let averagePercentage = (averageScore / Double(quiz.totalPoints)) * 100
        let highestScore = scores.max() ?? 0
        let lowestScore = scores.min() ?? 0
        
        // Calculate average time
        let times = submissions.compactMap { $0.timeSpentSeconds }
        let averageTime = times.isEmpty ? nil : times.reduce(0, +) / times.count
        
        // Calculate question analytics
        let questionAnalytics = calculateQuestionAnalytics(quiz: quiz, submissions: submissions)
        
        return QuizAnalytics(
            id: UUID(),
            quizID: quiz.id,
            quizTitle: quiz.title,
            totalSubmissions: totalSubmissions,
            averageScore: averageScore,
            averagePercentage: averagePercentage,
            highestScore: highestScore,
            lowestScore: lowestScore,
            totalPoints: quiz.totalPoints,
            completionRate: 100.0, // Assuming all submissions are complete
            averageTimeSeconds: averageTime,
            questionAnalytics: questionAnalytics
        )
    }
    
    private func calculateQuestionAnalytics(quiz: Quiz, submissions: [QuizSubmission]) -> [QuestionAnalytics] {
        var analyticsArray: [QuestionAnalytics] = []
        
        for question in quiz.questions {
            var totalAttempts = 0
            var correctAttempts = 0
            var totalPoints = 0.0
            var wrongAnswerCounts: [Int: Int] = [:]
            
            for submission in submissions {
                if let answer = submission.answers.first(where: { $0.questionID == question.id }) {
                    totalAttempts += 1
                    totalPoints += Double(answer.pointsEarned)
                    
                    if answer.isCorrect == true {
                        correctAttempts += 1
                    } else if question.type != .descriptive {
                        // Track wrong answers for MCQ
                        for index in answer.selectedOptionIndices {
                            wrongAnswerCounts[index, default: 0] += 1
                        }
                    }
                }
            }
            
            let averagePoints = totalAttempts > 0 ? totalPoints / Double(totalAttempts) : 0
            
            // Get most common wrong answers
            let commonWrong = wrongAnswerCounts
                .sorted { $0.value > $1.value }
                .prefix(3)
                .compactMap { index, count -> (String, Int)? in
                    guard index < question.options.count else { return nil }
                    return (question.options[index], count)
                }
            
            let analytics = QuestionAnalytics(
                id: question.id,
                questionText: question.text,
                questionType: question.type,
                totalAttempts: totalAttempts,
                correctAttempts: correctAttempts,
                averagePoints: averagePoints,
                maxPoints: question.points,
                commonWrongAnswers: commonWrong
            )
            
            analyticsArray.append(analytics)
        }
        
        return analyticsArray
    }
    
    // MARK: - Manual Grading
    
    func gradeDescriptiveAnswer(submissionID: UUID, questionID: UUID, points: Int, feedback: String?) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Fetch the submission
            guard let submission = await fetchSubmission(submissionID: submissionID) else {
                errorMessage = "Submission not found"
                return false
            }
            
            // Update the answer
            var updatedAnswers = submission.answers
            if let index = updatedAnswers.firstIndex(where: { $0.questionID == questionID }) {
                updatedAnswers[index].pointsEarned = points
                updatedAnswers[index].feedback = feedback
                updatedAnswers[index].isCorrect = points > 0
            }
            
            // Calculate new total score
            let newScore = updatedAnswers.reduce(0) { $0 + $1.pointsEarned }
            
            // Check if all questions are graded
            let allGraded = updatedAnswers.allSatisfy { $0.isCorrect != nil }
            let newStatus: SubmissionStatus = allGraded ? .graded : .pendingReview
            
            // Encode answers to JSON string for JSONB field
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let answersData = try encoder.encode(updatedAnswers)
            guard let answersString = String(data: answersData, encoding: .utf8) else {
                errorMessage = "Failed to encode answers"
                return false
            }
            
            // Create update struct
            struct SubmissionUpdate: Encodable {
                let answers: String
                let score: Int
                let status: String
                let graded_at: String?
            }
            
            let gradedAtString: String? = allGraded ? ISO8601DateFormatter().string(from: Date()) : nil
            
            let update = SubmissionUpdate(
                answers: answersString,
                score: newScore,
                status: newStatus.rawValue,
                graded_at: gradedAtString
            )
            
            // Update submission
            try await supabase
                .from("quiz_submissions")
                .update(update)
                .eq("id", value: submissionID.uuidString)
                .execute()
            
            return true
        } catch {
            errorMessage = "Failed to grade answer: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchCourseTitle(courseID: UUID) async -> String {
        do {
            struct CourseTitle: Codable {
                let title: String
            }
            
            let courses: [CourseTitle] = try await supabase
                .from("courses")
                .select("title")
                .eq("id", value: courseID.uuidString)
                .execute()
                .value
            
            return courses.first?.title ?? "Unknown Course"
        } catch {
            return "Unknown Course"
        }
    }
}
