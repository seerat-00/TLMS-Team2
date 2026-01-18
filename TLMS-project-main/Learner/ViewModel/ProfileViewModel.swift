//
//  ProfileViewModel.swift
//  TLMS-project-main
//
//  ViewModel for Learner Profile logic
//

import SwiftUI
import Supabase
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var completedCourses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSaving = false
    @Published var saveMessage: String?
    
    // Auth actions state
    @Published var showChangePassword = false
    @Published var resetEmailSent = false
    
    private let supabase = SupabaseManager.shared.client
    
    // MARK: - Initialization
    
    init(user: User?) {
        self.user = user
    }
    
    // MARK: - Data Fetching
    
    func loadProfileData() async {
        isLoading = true
        defer { isLoading = false }
        
        await fetchLatestUser()
        await fetchCompletedCourses()
    }
    
    func fetchLatestUser() async {
        guard let currentUserId = user?.id else { return }
        
        do {
            let fetchedUser: User = try await supabase
                .from("user_profiles")
                .select()
                .eq("id", value: currentUserId.uuidString)
                .single()
                .execute()
                .value
            
            self.user = fetchedUser
        } catch {
            print("Error fetching user: \(error)")
        }
    }
    
    func fetchCompletedCourses() async {
        guard let userId = user?.id else { return }
        
        do {
            // 1. Fetch enrollments that are completed (progress >= 1.0)
            let enrollments: [Enrollment] = try await supabase
                .from("enrollments")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            // Filter locally for completion
            let completedEnrollmentIds = enrollments.filter { ($0.progress ?? 0) >= 1.0 }.map { $0.courseID }
            
            if completedEnrollmentIds.isEmpty {
                self.completedCourses = []
                return
            }
            
            // 2. Fetch course details
            let courses: [Course] = try await supabase
                .from("courses")
                .select()
                .in("id", values: completedEnrollmentIds.map { $0.uuidString })
                .execute()
                .value
            
            self.completedCourses = courses
            
        } catch {
            print("Error fetching completed courses: \(error)")
            // Don't show error to user for this, just empty list
        }
    }
    
    // MARK: - Profile Management
    
    func updateProfile(fullName: String) async {
        guard let userId = user?.id else { return }
        guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Name cannot be empty"
            return
        }
        
        isSaving = true
        errorMessage = nil
        saveMessage = nil
        defer { isSaving = false }
        
        do {
            try await supabase
                .from("user_profiles")
                .update(["full_name": fullName])
                .eq("id", value: userId.uuidString)
                .execute()
            
            // Update local user object
            if var currentUser = user {
                await fetchLatestUser()
                saveMessage = "Profile updated successfully"
            }
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Auth Actions
    
    func sendPasswordResetEmail() async {
        guard let email = user?.email else { return }
        
        isLoading = true
        errorMessage = nil
        resetEmailSent = false
        defer { isLoading = false }
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            resetEmailSent = true
        } catch {
            errorMessage = "Failed to send reset email: \(error.localizedDescription)"
        }
    }
}