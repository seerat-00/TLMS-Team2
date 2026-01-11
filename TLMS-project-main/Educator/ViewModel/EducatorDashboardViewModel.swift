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
    @Published var recentCourses: [DashboardCourse] = []
    
    private let courseService = CourseService()
    
    init() {
        // Initialize with default values
        totalCourses = 0
        totalEnrollments = 0
        recentCourses = []
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
}

// MARK: - Dashboard Course Model

struct DashboardCourse: Identifiable {
    let id: UUID
    let title: String
    let status: CourseStatus
    let learnerCount: Int
}
