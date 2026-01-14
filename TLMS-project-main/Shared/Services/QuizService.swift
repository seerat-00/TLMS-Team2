//
//  QuizService.swift
//  TLMS-project-main
//
//  Service for managing quizzes
//

import Foundation
import Supabase
import Combine

@MainActor
class QuizService: ObservableObject {
    private let supabase: SupabaseClient
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        self.supabase = SupabaseManager.shared.client
    }
    
    // MARK: - Fetch Quizzes
    
    func fetchQuizzes(for courseID: UUID) async -> [Quiz] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let quizzes: [Quiz] = try await supabase
                .from("quizzes")
                .select()
                .eq("course_id", value: courseID.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            return quizzes
        } catch {
            errorMessage = "Failed to fetch quizzes: \(error.localizedDescription)"
            return []
        }
    }
    
    func fetchQuizzesByEducator(_ educatorID: UUID) async -> [Quiz] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let quizzes: [Quiz] = try await supabase
                .from("quizzes")
                .select()
                .eq("educator_id", value: educatorID.uuidString)
                .order("updated_at", ascending: false)
                .execute()
                .value
            return quizzes
        } catch {
            errorMessage = "Failed to fetch quizzes: \(error.localizedDescription)"
            return []
        }
    }
    
    func fetchQuiz(by quizID: UUID) async -> Quiz? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let quizzes: [Quiz] = try await supabase
                .from("quizzes")
                .select()
                .eq("id", value: quizID.uuidString)
                .execute()
                .value
            return quizzes.first
        } catch {
            errorMessage = "Failed to fetch quiz: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Save/Update
    
    func saveQuiz(_ quiz: Quiz) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("quizzes")
                .upsert(quiz)
                .execute()
            return true
        } catch {
            errorMessage = "Failed to save quiz: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Status Updates
    
    func updateQuizStatus(quizID: UUID, status: QuizStatus) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("quizzes")
                .update(["status": status.rawValue])
                .eq("id", value: quizID.uuidString)
                .execute()
            return true
        } catch {
            errorMessage = "Failed to update status: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Delete Quiz
    
    func deleteQuiz(quizID: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("quizzes")
                .delete()
                .eq("id", value: quizID.uuidString)
                .execute()
            return true
        } catch {
            errorMessage = "Failed to delete quiz: \(error.localizedDescription)"
            return false
        }
    }
}

