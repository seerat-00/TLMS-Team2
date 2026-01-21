//
//  EducatorDashboardViewModel.swift
//  TLMS-project-main
//
//  ViewModel for Educator Dashboard with mock data
//

import SwiftUI
import Combine

@MainActor
class EducatorDashboardViewModel: ObservableObject {
    @Published var totalCourses: Int = 0
    @Published var totalEnrollments: Int = 0
    @Published var totalQuizSubmissions: Int = 0
    @Published var recentCourses: [DashboardCourse] = []
    @Published var courseToDelete: DashboardCourse?
    @Published var showDeleteConfirmation = false
    @Published var courseToUnpublish: DashboardCourse?
    @Published var showUnpublishConfirmation = false
    
    private let courseService = CourseService()
    
    init() {
        // Initialize with default values
        totalCourses = 0
        totalEnrollments = 0
        recentCourses = []
    }
    
    var draftCourses: [DashboardCourse] {
        recentCourses.filter { $0.status == .draft }
    }
    
    var otherCourses: [DashboardCourse] {
        recentCourses.filter { $0.status != .draft }
    }
    
    func loadData(educatorID: UUID) async {
        let courses = await courseService.fetchCourses(for: educatorID)
        
        self.totalCourses = courses.count
        
        // Map to DashboardCourse for display
        self.recentCourses = courses.map { course in
            DashboardCourse(
                id: course.id,
                title: course.title,
                status: course.status,
                learnerCount: 0 // TODO: Implement enrollment count
            )
        }
    }
    
    func deleteCourse(_ course: DashboardCourse) async -> Bool {
        let success = await courseService.deleteCourse(courseID: course.id)
        if success {
            // Remove from local array
            recentCourses.removeAll { $0.id == course.id }
            totalCourses = recentCourses.count
        }
        return success
    }
    
    func confirmDelete(_ course: DashboardCourse) {
        courseToDelete = course
        showDeleteConfirmation = true
    }
    
    func confirmUnpublish(_ course: DashboardCourse) {
        courseToUnpublish = course
        showUnpublishConfirmation = true
    }
    
    func unpublishCourse(_ course: DashboardCourse) async -> Bool {
        let success = await courseService.updateCourseStatus(courseID: course.id, status: .draft)
        if success {
            // Update local array
            if let index = recentCourses.firstIndex(where: { $0.id == course.id }) {
                recentCourses[index] = DashboardCourse(
                    id: course.id,
                    title: course.title,
                    status: .draft,
                    learnerCount: course.learnerCount
                )
            }
        }
        return success
    }
}

// MARK: - Dashboard Course Model

struct DashboardCourse: Identifiable {
    let id: UUID
    let title: String
    let status: CourseStatus
    let learnerCount: Int
}
