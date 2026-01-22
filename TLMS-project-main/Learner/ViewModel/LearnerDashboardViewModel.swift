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
    @Published var upcomingDeadlines: [CourseDeadline] = []
    @Published var completedCoursesCount: Int = 0
    
    @Published private(set) var courseProgressMap: [UUID: Double] = [:]
    
    // Filter State
    @Published var searchText: String = ""
    @Published var selectedCategory: String? = nil
    @Published var selectedSortOption: CourseSortOption = .relevance
    
    // Completed course metadata for Relevance sorting
    @Published private(set) var completedCourseCategories: Set<String> = []
    @Published private(set) var completedCourseEducators: Set<UUID> = []
    
    
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
    
    // NEW: Filtered Enrolled Courses
    @Published var selectedEnrollmentFilter: CourseEnrollmentFilter = .inProgress
    @Published private var completedCourseIds: Set<UUID> = []

    var filteredEnrolledCourses: [Course] {
        switch selectedEnrollmentFilter {
        case .inProgress:
            return enrolledCourses.filter { !completedCourseIds.contains($0.id) }
        case .completed:
            return enrolledCourses.filter { completedCourseIds.contains($0.id) }
        }
    }
    
    // MARK: - Data Loading
    func loadData(userId: UUID) async {
        isLoading = true

        // 1️⃣ Fetch core data in parallel
        async let published = courseService.fetchPublishedCourses()
        async let enrolled = courseService.fetchEnrolledCourses(userID: userId)

        let (pub, enr) = await (published, enrolled)

        // 2️⃣ Update core state
        self.publishedCourses = pub
        self.enrolledCourses = enr

        // 3️⃣ Derived state (depends on enrollments)
        await calculateCompletedCourses(userId: userId)
        await cacheCourseProgress(userId: userId)

        // 4️⃣ Secondary side-effects
        await checkForInactivityNudge(userId: userId)
        await scheduleDeadlineNotifications(userId: userId)
        await loadDeadlines(userId: userId)

        // 5️⃣ Done
        isLoading = false
    }
    
//    private func cacheCourseProgress(userId: UUID) async {
//        do {
//            struct EnrollmentProgress: Codable {
//                let course_id: UUID
//                let progress: Double?
//            }
//
//            let enrollments: [EnrollmentProgress] = try await courseService.supabase
//                .from("enrollments")
//                .select("course_id, progress")
//                .eq("user_id", value: userId)
//                .execute()
//                .value
//
//            var map: [UUID: Double] = [:]
//            for enrollment in enrollments {
//                map[enrollment.course_id] = enrollment.progress ?? 0.0
//            }
//
//            self.courseProgressMap = map
//        } catch {
//            print("❌ Failed to cache course progress:", error)
//            self.courseProgressMap = [:]
//        }
//    }
    
    private func cacheCourseProgress(userId: UUID) async {
        do {
            let rows = try await courseService.fetchEnrollmentProgress(userId: userId)
            self.courseProgressMap = Dictionary(uniqueKeysWithValues: rows)
        } catch {
            print("❌ Failed to cache course progress:", error)
            self.courseProgressMap = [:]
        }
    }

    
    func loadDeadlines(userId: UUID) async {
        let deadlines = await courseService.fetchDeadlinesForLearner(userId: userId)

        // only future deadlines
        let future = deadlines.filter { $0.deadlineAt > Date() }

        // show only next 5 deadlines
        self.upcomingDeadlines = Array(future.prefix(5))
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

    func getCachedProgress(for courseId: UUID) -> Double {
        courseProgressMap[courseId] ?? 0.0
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
    // MARK: - Deadline Reminders (NEW ✅)
    func scheduleDeadlineNotifications(userId: UUID) async {

        // 1) permission
        let granted = await LocalNotificationManager.shared.requestPermission()
        if !granted { return }

        // 2) fetch deadlines
        let deadlines = await courseService.fetchDeadlinesForLearner(userId: userId)

        // 3) schedule each deadline (1 hour before)
        for deadline in deadlines {

            let reminderTime = deadline.deadlineAt.addingTimeInterval(-3600) // 1 hour before

            // ignore if reminder time already passed
            if reminderTime <= Date() { continue }

            await LocalNotificationManager.shared.scheduleDeadlineReminder(
                deadlineId: deadline.id,
                title: deadline.title,
                deadlineAt: reminderTime
            )
        }
    }

    
    func isEnrolled(_ course: Course) -> Bool {
        enrolledCourses.contains(where: { $0.id == course.id })
    }
    
    /// Get course progress for a user
//    func getCourseProgress(courseId: UUID, userId: UUID) async -> Double {
//        do {
//            struct EnrollmentProgress: Codable {
//                let progress: Double?
//            }
//            
//            let result: [EnrollmentProgress] = try await courseService.supabase
//                .from("enrollments")
//                .select("progress")
//                .eq("user_id", value: userId)
//                .eq("course_id", value: courseId)
//                .execute()
//                .value
//            
//            return result.first?.progress ?? 0.0
//        } catch {
//            print("❌ Error fetching progress: \(error.localizedDescription)")
//            return 0.0
//        }
//    }

    
//    private func calculateCompletedCourses(userId: UUID) async {
//        // Fetch all enrollments with progress
//        do {
//            struct EnrollmentProgress: Codable {
//                let course_id: UUID
//                let progress: Double?
//            }
//            
//            let enrollments: [EnrollmentProgress] = try await courseService.supabase
//                .from("enrollments")
//                .select("course_id, progress")
//                .eq("user_id", value: userId)
//                .execute()
//                .value
//            
//            let completed = enrollments.filter { ($0.progress ?? 0) >= 1.0 }
//            self.completedCoursesCount = completed.count
//            self.completedCourseIds = Set(completed.map { $0.course_id })
//            
//        } catch {
//            print("Failed to calculate completed courses: \(error)")
//        }
//    }
    
    private func calculateCompletedCourses(userId: UUID) async {
        do {
            let rows = try await courseService.fetchEnrollmentProgress(userId: userId)

            let completed = rows.filter { $0.progress >= 1.0 }
            self.completedCoursesCount = completed.count
            self.completedCourseIds = Set(completed.map { $0.courseId })
            
            // Extract categories and educators from completed enrolled courses
            let completedCourses = enrolledCourses.filter { completedCourseIds.contains($0.id) }
            self.completedCourseCategories = Set(completedCourses.map { $0.category })
            self.completedCourseEducators = Set(completedCourses.map { $0.educatorID })
        } catch {
            print("Failed to calculate completed courses:", error)
        }
    }
}

