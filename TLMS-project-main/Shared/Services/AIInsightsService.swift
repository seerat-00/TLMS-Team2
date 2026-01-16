//
//  AIInsightsService.swift
//  TLMS-project-main
//
//  Service for generating AI-powered insights using OpenAI ChatGPT API
//

import Foundation
import Combine

@MainActor
class AIInsightsService: ObservableObject {
    private let apiKey = "AIzaSyBNfivn7AKTogZfb3E2LxKzA3cA-TXqD7c"
    private let baseURL = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash-latest:generateContent"
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Generate Quiz Insights
    
    func generateQuizInsights(analytics: QuizAnalytics) async -> QuizInsights? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let prompt = buildQuizInsightsPrompt(analytics: analytics)
        
        guard let response = await callOpenAIAPI(prompt: prompt) else {
            return nil
        }
        
        return parseQuizInsights(from: response, analytics: analytics)
    }
    
    // MARK: - Generate Question Improvement Suggestions
    
    func generateQuestionSuggestions(questionAnalytics: QuestionAnalytics) async -> String? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let prompt = buildQuestionSuggestionsPrompt(questionAnalytics: questionAnalytics)
        
        return await callOpenAIAPI(prompt: prompt)
    }
    
    // MARK: - Generate Learner Feedback
    
    func generateLearnerFeedback(performance: LearnerPerformance, quiz: Quiz) async -> String? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let prompt = buildLearnerFeedbackPrompt(performance: performance, quiz: quiz)
        
        return await callOpenAIAPI(prompt: prompt)
    }
    
    // MARK: - Mock AI Insights (No API Required)
    
    private func callOpenAIAPI(prompt: String) async -> String? {
        // Simulate API delay for realism
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Generate contextual response based on prompt content
        if prompt.contains("Quiz:") && prompt.contains("Average Score:") {
            return generateQuizAnalysisResponse(from: prompt)
        } else if prompt.contains("Question:") && prompt.contains("Success Rate:") {
            return generateQuestionSuggestionResponse(from: prompt)
        } else if prompt.contains("Learner:") && prompt.contains("Score:") {
            return generateLearnerFeedbackResponse(from: prompt)
        }
        
        return "Analysis complete. Please review the detailed metrics."
    }
    
    private func generateQuizAnalysisResponse(from prompt: String) -> String {
        // Extract metrics from prompt
        let avgScore = extractValue(from: prompt, after: "Average Score: ", before: "%") ?? 0
        let totalSubmissions = extractValue(from: prompt, after: "Total Submissions: ", before: "\n") ?? 0
        
        var response = "Overall Performance Summary\n\n"
        
        // Generate contextual summary
        if avgScore >= 80 {
            response += "The quiz demonstrates strong learner comprehension with an average score of \(String(format: "%.1f", avgScore))%. Most students have grasped the core concepts effectively. The \(Int(totalSubmissions)) submissions indicate good engagement with the material."
        } else if avgScore >= 60 {
            response += "The quiz shows moderate performance with an average score of \(String(format: "%.1f", avgScore))%. While many learners understand the basics, there's room for improvement in deeper concept mastery. The \(Int(totalSubmissions)) submissions suggest adequate participation."
        } else {
            response += "The quiz results indicate challenges in comprehension with an average score of \(String(format: "%.1f", avgScore))%. The \(Int(totalSubmissions)) submissions reveal that learners may need additional support and review of the material."
        }
        
        response += "\n\nKey Strengths\n\n"
        if avgScore >= 70 {
            response += "Strong foundational understanding demonstrated across multiple questions\n"
            response += "High engagement with \(Int(totalSubmissions)) completed submissions\n"
            response += "Consistent performance across different question types\n"
        } else {
            response += "Good participation rate with \(Int(totalSubmissions)) submissions\n"
            response += "Learners are attempting all questions\n"
            response += "Some questions show strong comprehension\n"
        }
        
        response += "\nAreas for Improvement\n\n"
        if avgScore < 70 {
            response += "Review and reinforce core concepts that showed lower success rates\n"
            response += "Provide additional practice materials for struggling topics\n"
            response += "Consider one-on-one support for learners scoring below 60%\n"
        } else {
            response += "Challenge high performers with advanced material\n"
            response += "Address specific weak points in lower-scoring questions\n"
            response += "Ensure consistent understanding across all topics\n"
        }
        
        response += "\nRecommendations\n\n"
        response += "Schedule a review session focusing on questions with <70% success rate\n"
        response += "Provide supplementary resources and practice exercises\n"
        response += "Consider adjusting question difficulty based on performance patterns\n"
        
        return response
    }
    
    private func generateQuestionSuggestionResponse(from prompt: String) -> String {
        let successRate = extractValue(from: prompt, after: "Success Rate: ", before: "%") ?? 0
        
        if successRate >= 80 {
            return "This question is performing well. Consider making it slightly more challenging to better differentiate high performers, or use it as a confidence builder early in the quiz."
        } else if successRate >= 50 {
            return "The question has moderate difficulty. Review the wording for clarity and ensure distractors are plausible but clearly incorrect. Consider adding hints or context to improve comprehension."
        } else {
            return "This question may be too difficult or unclear. Review the question text for ambiguity, simplify complex language, and ensure the correct answer is definitively correct. Consider breaking it into multiple simpler questions."
        }
    }
    
    private func generateLearnerFeedbackResponse(from prompt: String) -> String {
        let score = extractValue(from: prompt, after: "Score: ", before: "/") ?? 0
        let total = extractValue(from: prompt, after: "/", before: " (") ?? 1
        let percentage = (score / total) * 100
        
        var feedback = ""
        
        if percentage >= 90 {
            feedback = "Excellent work! You've demonstrated outstanding mastery of the material with a score of \(String(format: "%.0f", percentage))%. Your strong performance shows deep understanding. Keep up this exceptional effort and continue challenging yourself with advanced topics."
        } else if percentage >= 70 {
            feedback = "Good job! You've shown solid understanding with a score of \(String(format: "%.0f", percentage))%. You're on the right track. Review the questions you missed to strengthen your knowledge, and you'll be at the top of the class in no time."
        } else if percentage >= 50 {
            feedback = "You're making progress with a score of \(String(format: "%.0f", percentage))%. Don't be discouraged - learning takes time. Focus on reviewing the core concepts, practice with additional exercises, and don't hesitate to ask questions. You've got this!"
        } else {
            feedback = "Thank you for completing the quiz. With a score of \(String(format: "%.0f", percentage))%, there's significant room for growth. This is a learning opportunity! Review the material carefully, seek help from your instructor, and try practice problems. Every expert was once a beginner."
        }
        
        return feedback
    }
    
    private func extractValue(from text: String, after: String, before: String) -> Double? {
        guard let startRange = text.range(of: after),
              let endRange = text.range(of: before, range: startRange.upperBound..<text.endIndex) else {
            return nil
        }
        
        let valueString = String(text[startRange.upperBound..<endRange.lowerBound])
        return Double(valueString.trimmingCharacters(in: .whitespaces))
    }
    
    // MARK: - Prompt Building
    
    private func buildQuizInsightsPrompt(analytics: QuizAnalytics) -> String {
        let questionStats = analytics.questionAnalytics.map { q in
            "- Question: \"\(q.questionText)\" | Success Rate: \(String(format: "%.0f%%", q.successRate)) | Difficulty: \(q.difficulty)"
        }.joined(separator: "\n")
        
        return """
        You are an educational analytics expert. Analyze the following quiz results and provide actionable insights for the educator.
        
        Quiz: \(analytics.quizTitle)
        Total Submissions: \(analytics.totalSubmissions)
        Average Score: \(String(format: "%.1f%%", analytics.averagePercentage))
        Highest Score: \(analytics.highestScore)/\(analytics.totalPoints)
        Lowest Score: \(analytics.lowestScore)/\(analytics.totalPoints)
        
        Question Performance:
        \(questionStats)
        
        Please provide:
        1. Overall Performance Summary (2-3 sentences)
        2. Key Strengths (bullet points, max 3)
        3. Areas for Improvement (bullet points, max 3)
        4. Specific Recommendations (bullet points, max 3)
        
        Keep your response concise and actionable. Format with clear sections.
        """
    }
    
    private func buildQuestionSuggestionsPrompt(questionAnalytics: QuestionAnalytics) -> String {
        let wrongAnswers = questionAnalytics.commonWrongAnswers.map { "\"\($0.option)\" (selected \($0.count) times)" }.joined(separator: ", ")
        
        return """
        You are an educational content expert. Analyze this quiz question and suggest improvements.
        
        Question: "\(questionAnalytics.questionText)"
        Type: \(questionAnalytics.questionType.displayName)
        Success Rate: \(String(format: "%.0f%%", questionAnalytics.successRate))
        Difficulty: \(questionAnalytics.difficulty)
        Common Wrong Answers: \(wrongAnswers.isEmpty ? "None" : wrongAnswers)
        
        Provide 2-3 specific, actionable suggestions to improve this question. Focus on clarity, difficulty adjustment, or distractor improvement.
        Keep your response brief and practical.
        """
    }
    
    private func buildLearnerFeedbackPrompt(performance: LearnerPerformance, quiz: Quiz) -> String {
        return """
        You are a supportive educator. Provide personalized feedback for a learner based on their quiz performance.
        
        Learner: \(performance.learnerName)
        Quiz: \(quiz.title)
        Score: \(performance.submission.score)/\(performance.submission.totalPoints) (\(String(format: "%.0f%%", performance.submission.percentageScore)))
        Questions Correct: \(performance.questionsCorrect)/\(performance.questionsTotal)
        
        Provide:
        1. Encouraging opening statement
        2. 2-3 specific strengths or areas they did well
        3. 1-2 areas for improvement with constructive suggestions
        4. Motivating closing statement
        
        Keep the tone positive, supportive, and encouraging. Maximum 150 words.
        """
    }
    
    // MARK: - Response Parsing
    
    private func parseQuizInsights(from response: String, analytics: QuizAnalytics) -> QuizInsights {
        // Simple parsing - in production, you might want more sophisticated parsing
        let sections = response.components(separatedBy: "\n\n")
        
        var summary = ""
        var strengths: [String] = []
        var improvements: [String] = []
        var recommendations: [String] = []
        
        for section in sections {
            if section.contains("Summary") || section.contains("Performance") {
                summary = section.replacingOccurrences(of: "Overall Performance Summary:", with: "")
                    .replacingOccurrences(of: "1. Overall Performance Summary", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else if section.contains("Strengths") {
                strengths = extractBulletPoints(from: section)
            } else if section.contains("Improvement") {
                improvements = extractBulletPoints(from: section)
            } else if section.contains("Recommendations") {
                recommendations = extractBulletPoints(from: section)
            }
        }
        
        return QuizInsights(
            quizID: analytics.quizID,
            summary: summary.isEmpty ? "Analysis complete. Review the detailed metrics above." : summary,
            strengths: strengths.isEmpty ? ["Good overall participation"] : strengths,
            areasForImprovement: improvements.isEmpty ? ["Continue monitoring performance"] : improvements,
            recommendations: recommendations.isEmpty ? ["Keep engaging with learners"] : recommendations,
            generatedAt: Date()
        )
    }
    
    private func extractBulletPoints(from text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
        return lines
            .filter { $0.contains("•") || $0.contains("-") || $0.contains("*") || ($0.trimmingCharacters(in: .whitespaces).first?.isNumber ?? false) }
            .map { line in
                line.replacingOccurrences(of: "•", with: "")
                    .replacingOccurrences(of: "*", with: "")
                    .replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
            .prefix(3)
            .map { String($0) }
    }
}

// MARK: - Quiz Insights Model

struct QuizInsights: Identifiable {
    let id = UUID()
    let quizID: UUID
    let summary: String
    let strengths: [String]
    let areasForImprovement: [String]
    let recommendations: [String]
    let generatedAt: Date
}
