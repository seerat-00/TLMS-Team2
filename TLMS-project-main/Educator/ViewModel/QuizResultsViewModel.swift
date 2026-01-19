//
//  QuizResultsViewModel.swift
//  TLMS-project-main
//
//  ViewModel for managing quiz results and analytics
//

import Foundation
import SwiftUI
import Combine

@MainActor
class QuizResultsViewModel: ObservableObject {
    @Published var quizResultsSummaries: [QuizResultsSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCourseFilter: String = "All Courses"
    
    private let service = QuizResultsService()
    private let quizService = QuizService()
    
    var filteredResults: [QuizResultsSummary] {
        var results = quizResultsSummaries
        
        // Filter by search text
        if !searchText.isEmpty {
            results = results.filter { summary in
                summary.quizTitle.localizedCaseInsensitiveContains(searchText) ||
                summary.courseTitle.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by course
        if selectedCourseFilter != "All Courses" {
            results = results.filter { $0.courseTitle == selectedCourseFilter }
        }
        
        return results
    }
    
    var availableCourses: [String] {
        let courses = Set(quizResultsSummaries.map { $0.courseTitle })
        return ["All Courses"] + courses.sorted()
    }
    
    func loadQuizResults(educatorID: UUID) async {
        isLoading = true
        errorMessage = nil
        
        let summaries = await service.fetchEducatorQuizResults(educatorID: educatorID)
        
        if let error = service.errorMessage {
            errorMessage = error
        } else {
            quizResultsSummaries = summaries
        }
        
        isLoading = false
    }
    
    func refresh(educatorID: UUID) async {
        await loadQuizResults(educatorID: educatorID)
    }
}

@MainActor
class QuizAnalyticsViewModel: ObservableObject {
    @Published var quiz: Quiz?
    @Published var submissions: [QuizSubmission] = []
    @Published var analytics: QuizAnalytics?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedSubmission: QuizSubmission?
    @Published var showingLearnerPerformance = false
    @Published var aiInsights: QuizInsights?
    @Published var isLoadingInsights = false
    
    private let service = QuizResultsService()
    private let quizService = QuizService()
    private let aiService = AIInsightsService()
    
    var scoreDistribution: [ScoreDistributionData] {
        guard let totalPoints = quiz?.totalPoints, totalPoints > 0 else {
            return []
        }
        
        let ranges: [(String, Double, Double, Color)] = [
            ("90-100%", 90, 100, AppTheme.successGreen),
            ("80-89%", 80, 89.99, Color.green),
            ("70-79%", 70, 79.99, AppTheme.warningOrange),
            ("60-69%", 60, 69.99, Color.orange),
            ("Below 60%", 0, 59.99, AppTheme.errorRed)
        ]
        
        return ranges.map { item in
            let (label, minScore, maxScore, color) = item
            let count = submissions.filter { submission in
                let percentage = submission.percentageScore
                return percentage >= minScore && percentage <= maxScore
            }.count
            
            return ScoreDistributionData(
                range: label,
                count: count,
                color: color
            )
        }
    }
    
    var topPerformers: [LearnerPerformance] {
        let sorted = submissions
            .sorted { $0.score > $1.score }
            .prefix(5)
        
        return sorted.enumerated().map { index, submission in
            let correctAnswers = submission.answers.filter { $0.isCorrect == true }.count
            return LearnerPerformance(
                id: submission.id,
                learnerID: submission.learnerID,
                learnerName: submission.learnerName ?? "Unknown",
                learnerEmail: submission.learnerEmail ?? "",
                submission: submission,
                rank: index + 1,
                questionsCorrect: correctAnswers,
                questionsTotal: submission.answers.count
            )
        }
    }
    
    var strugglingLearners: [LearnerPerformance] {
        guard let totalPoints = quiz?.totalPoints, totalPoints > 0 else {
            return []
        }
        
        let struggling = submissions
            .filter { $0.percentageScore < 60 }
            .sorted { $0.score < $1.score }
            .prefix(5)
        
        return struggling.map { submission in
            let correctAnswers = submission.answers.filter { $0.isCorrect == true }.count
            return LearnerPerformance(
                id: submission.id,
                learnerID: submission.learnerID,
                learnerName: submission.learnerName ?? "Unknown",
                learnerEmail: submission.learnerEmail ?? "",
                submission: submission,
                rank: nil,
                questionsCorrect: correctAnswers,
                questionsTotal: submission.answers.count
            )
        }
    }
    
    var needsGrading: [QuizSubmission] {
        submissions.filter { $0.status == .pendingReview }
    }
    
    func loadQuizAnalytics(quizID: UUID) async {
        isLoading = true
        errorMessage = nil
        
        // Fetch quiz details
        if let fetchedQuiz = await quizService.fetchQuiz(by: quizID) {
            quiz = fetchedQuiz
        } else {
            errorMessage = "Failed to load quiz details"
            isLoading = false
            return
        }
        
        // Fetch submissions
        let fetchedSubmissions = await service.fetchQuizSubmissions(quizID: quizID)
        submissions = fetchedSubmissions
        
        // Calculate analytics
        if let quiz = quiz {
            analytics = service.calculateQuizAnalytics(quiz: quiz, submissions: submissions)
        }
        
        if let error = service.errorMessage {
            errorMessage = error
        }
        
        isLoading = false
        
        // Generate AI insights automatically
        if let analytics = analytics, analytics.totalSubmissions > 0 {
            await generateAIInsights()
        }
    }
    
    func generateAIInsights() async {
        guard let analytics = analytics else { return }
        
        isLoadingInsights = true
        aiInsights = await aiService.generateQuizInsights(analytics: analytics)
        isLoadingInsights = false
    }
    
    func selectSubmission(_ submission: QuizSubmission) {
        selectedSubmission = submission
        showingLearnerPerformance = true
    }
}

// MARK: - Helper Models

struct ScoreDistributionData: Identifiable {
    let id = UUID()
    let range: String
    let count: Int
    let color: Color
}
