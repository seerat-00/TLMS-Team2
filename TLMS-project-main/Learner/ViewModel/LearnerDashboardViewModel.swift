//
//  LearnerDashboardViewModel.swift
//  TLMS-project-main
//
//  Created by AutoAgent on 18/01/26.
//

import SwiftUI
import Combine
import PostgREST
import Supabase

@MainActor
final class LearnerDashboardViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published var publishedCourses: [Course] = []
    @Published var enrolledCourses: [Course] = []
    @Published var isLoading: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String? = nil
    
    // Filter State
    @Published var searchText: String = ""
    @Published var selectedCategory: String? = nil
    @Published var selectedSortOption: CourseSortOption = .relevance
   

    
    private let courseService = CourseService()
    
    // MARK: - Derived Data
    var filteredCourses: [Course] {
        // 1. Apply search filter
        var filtered = publishedCourses
        if !searchText.isEmpty {
            filtered = filtered.filter { course in
                course.title.localizedCaseInsensitiveContains(searchText) ||
                course.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 2. Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // 3. Apply sorting
        switch selectedSortOption {
        case .relevance:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .popularity:
            return filtered.sorted { $0.enrollmentCount > $1.enrollmentCount }
        case .newest:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    // MARK: - Data Loading
    func loadData(userId: UUID) async {
        isLoading = true
        
        async let published = courseService.fetchPublishedCourses()
        async let enrolled = courseService.fetchEnrolledCourses(userID: userId)
        
        let (pub, enr) = await (published, enrolled)
        
        self.publishedCourses = pub
        self.enrolledCourses = enr
        self.isLoading = false
        await checkForInactivityNudge(userId: userId)
        
    }
    private func checkForInactivityNudge(userId: UUID) async {
        let activityService = ActivityService()
        guard let lastActive = await activityService.fetchLastActive(userId: userId) else { return }

        let hoursInactive = Date().timeIntervalSince(lastActive) / 3600

        if hoursInactive >= 24 {
            NotificationManager.shared.scheduleNotification(
                id: "nudge_\(userId.uuidString)",
                title: "Keep Learning 🚀",
                body: "You haven’t studied in a while. Let’s continue your course today!",
                date: Date().addingTimeInterval(10) // 10 sec test, later schedule immediate
            )
        }
    }

    
    // MARK: - Actions
    func enroll(course: Course, userId: UUID) async -> Bool {
        let success = await courseService.enrollInCourse(
            courseID: course.id,
            userID: userId
        )
        
        if success {
             await loadData(userId: userId)
             return true
        } else {
            self.errorMessage = courseService.errorMessage ?? "Failed to enroll in course"
            self.showingError = true
            return false
        }
    }
    
    func isEnrolled(_ course: Course) -> Bool {
        enrolledCourses.contains(where: { $0.id == course.id })
    }
    
    /// Get course progress for a user
    func getCourseProgress(courseId: UUID, userId: UUID) async -> Double {
        do {
            struct EnrollmentProgress: Codable {
                let progress: Double?
            }
            
            let result: [EnrollmentProgress] = try await courseService.supabase
                .from("enrollments")
                .select("progress")
                .eq("user_id", value: userId)
                .eq("course_id", value: courseId)
                .execute()
                .value
            
            return result.first?.progress ?? 0.0
        } catch {
            print("❌ Error fetching progress: \(error.localizedDescription)")
            return 0.0
        }
    }
}

