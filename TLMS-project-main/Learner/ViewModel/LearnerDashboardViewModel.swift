//
//  LearnerDashboardViewModel.swift
//  TLMS-project-main
//
//  Created by AutoAgent on 18/01/26.
//

import SwiftUI
import Combine

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
}
