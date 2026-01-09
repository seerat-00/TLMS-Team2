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
    
    init() {
        // Initialize with real data - zeros for new educators
        // In a real app, this would fetch from backend/database
        totalCourses = 0
        totalEnrollments = 0
        recentCourses = []
    }
}

// MARK: - Dashboard Course Model

struct DashboardCourse: Identifiable {
    let id: UUID
    let title: String
    let status: CourseStatus
    let learnerCount: Int
}

enum CourseStatus: String {
    case draft = "Draft"
    case published = "Published"
    
    var color: Color {
        switch self {
        case .draft: return .orange
        case .published: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .draft: return "pencil.circle.fill"
        case .published: return "checkmark.circle.fill"
        }
    }
}
