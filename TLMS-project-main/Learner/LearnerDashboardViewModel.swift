//
//  LearnerDashboardViewModel.swift
//  TLMS-project-main
//
//  Created by Chehak on 16/01/26.
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
    @Published var selectedSortOption: CourseSortOption = .relevance

    private let courseService = CourseService()

    // MARK: - Derived Data
    func browseOnlyCourses() -> [Course] {
        publishedCourses.filter { course in
            !enrolledCourses.contains(where: { $0.id == course.id })
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

    // MARK: - Enrollment
    func enroll(course: Course, userId: UUID) async {
        let success = await courseService.enrollInCourse(
            courseID: course.id,
            userID: userId
        )

        if success {
            await loadData(userId: userId)
        } else {
            showingError = true
        }
    }
}
