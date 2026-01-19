//
//  CourseService.swift
//  TLMS-project-main
//
//  Service for managing courses
//

import Foundation
import Supabase
import Combine

@MainActor
class CourseService: ObservableObject {
    private let supabase: SupabaseClient
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        self.supabase = SupabaseManager.shared.client
    }
    
    // MARK: - Fetch Courses
    
    func fetchCourses(for educatorID: UUID) async -> [Course] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let courses: [Course] = try await supabase
                .from("courses")
                .select()
                .eq("educator_id", value: educatorID.uuidString)
                .order("updated_at", ascending: false)
                .execute()
                .value
            return courses
        } catch {
            errorMessage = "Failed to fetch courses: \(error.localizedDescription)"
            return []
        }
    }
    
    func fetchPendingCourses() async -> [Course] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let courses: [Course] = try await supabase
                .from("courses")
                .select()
                .eq("status", value: "pending_review")
                .order("updated_at", ascending: false)
                .execute()
                .value
            return courses
        } catch {
            errorMessage = "Failed to fetch pending courses: \(error.localizedDescription)"
            return []
        }
    }
    
    func fetchPublishedCourses() async -> [Course] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        print("DEBUG: Fetching published courses...")
        
        do {
            // First, fetch all published courses
            var courses: [Course] = try await supabase
                .from("courses")
                .select()
                .eq("status", value: "published")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("DEBUG: Fetched \(courses.count) published courses")
            
            // Then, fetch all enrollments to calculate counts
            let enrollments: [Enrollment] = try await supabase
                .from("enrollments")
                .select()
                .execute()
                .value
            
            // Count enrollments per course
            var enrollmentCounts: [UUID: Int] = [:]
            for enrollment in enrollments {
                enrollmentCounts[enrollment.courseID, default: 0] += 1
            }
            
            // Update courses with enrollment counts
            for i in 0..<courses.count {
                courses[i].enrollmentCount = enrollmentCounts[courses[i].id] ?? 0
            }
            
            print("DEBUG: Updated enrollment counts for courses")
            return courses
        } catch {
            print("DEBUG: Error fetching courses: \(error)")
            errorMessage = "Failed to fetch published courses: \(error.localizedDescription)"
            return []
        }
    }
    
    func fetchCourse(by courseID: UUID) async -> Course? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let courses: [Course] = try await supabase
                .from("courses")
                .select()
                .eq("id", value: courseID.uuidString)
                .execute()
                .value
            return courses.first
        } catch {
            errorMessage = "Failed to fetch course: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Save/Update
    
    func saveCourse(_ course: Course) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("courses")
                .upsert(course)
                .execute()
            return true
        } catch {
            errorMessage = "Failed to save course: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Status Updates
    
    func updateCourseStatus(courseID: UUID, status: CourseStatus, reason: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Create encodable update struct
            struct CourseStatusUpdate: Encodable {
                let status: String
                let removal_reason: String?
            }
            
            let updateData = CourseStatusUpdate(
                status: status.rawValue,
                removal_reason: reason
            )
            
            try await supabase
                .from("courses")
                .update(updateData)
                .eq("id", value: courseID.uuidString)
                .execute()
            return true
        } catch {
            errorMessage = "Failed to update status: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Delete Course
    
    func deleteCourse(courseID: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("courses")
                .delete()
                .eq("id", value: courseID.uuidString)
                .execute()
            return true
        } catch {
            errorMessage = "Failed to delete course: \(error.localizedDescription)"
            return false
        }
    }
    // MARK: - Enrollment

    func enrollInCourse(courseID: UUID, userID: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let enrollment = Enrollment(userID: userID, courseID: courseID)
            try await supabase
                .from("enrollments")
                .insert(enrollment)
                .execute()
            return true
        } catch {
            // Check for duplicate key error (already enrolled)
            if error.localizedDescription.contains("duplicate key") {
                 errorMessage = "You are already enrolled in this course."
            } else {
                errorMessage = "Failed to enroll: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    func fetchEnrolledCourses(userID: UUID) async -> [Course] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // 1. Get enrollments for user
            let enrollments: [Enrollment] = try await supabase
                .from("enrollments")
                .select()
                .eq("user_id", value: userID)
                .execute()
                .value
            
            let courseIDs = enrollments.map { $0.courseID }
            
            if courseIDs.isEmpty {
                return []
            }
            
            // 2. Fetch courses matching IDs
            var courses: [Course] = try await supabase
                .from("courses")
                .select()
                .in("id", values: courseIDs)
                .execute()
                .value
            
            // 3. Fetch all enrollments to calculate counts
            let allEnrollments: [Enrollment] = try await supabase
                .from("enrollments")
                .select()
                .execute()
                .value
            
            // Count enrollments per course
            var enrollmentCounts: [UUID: Int] = [:]
            for enrollment in allEnrollments {
                enrollmentCounts[enrollment.courseID, default: 0] += 1
            }
            
            // Update courses with enrollment counts
            for i in 0..<courses.count {
                courses[i].enrollmentCount = enrollmentCounts[courses[i].id] ?? 0
            }
            
            return courses
        } catch {
            errorMessage = "Failed to fetch enrolled courses: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Admin Analytics Methods
    
    func fetchAllActiveCourses() async -> [Course] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let courses: [Course] = try await supabase
                .from("courses")
                .select()
                .eq("status", value: "published")
                .order("created_at", ascending: false)
                .execute()
                .value
            return courses
        } catch {
            errorMessage = "Failed to fetch active courses: \(error.localizedDescription)"
            return []
        }
    }
    
    func fetchAllEnrollments() async -> [Enrollment] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let enrollments: [Enrollment] = try await supabase
                .from("enrollments")
                .select()
                .execute()
                .value
            return enrollments
        } catch {
            print("❌ Error fetching enrollments: \(error)") // Added debug print
            errorMessage = "Failed to fetch enrollments: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Progress Tracking
    
    /// Mark a lesson as complete for a user
    func markLessonComplete(userId: UUID, courseId: UUID, lessonId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            struct LessonCompletion: Codable {
                let id: UUID?
                let userId: UUID
                let courseId: UUID
                let lessonId: UUID
                let completedAt: Date
                
                enum CodingKeys: String, CodingKey {
                    case id
                    case userId = "user_id"
                    case courseId = "course_id"
                    case lessonId = "lesson_id"
                    case completedAt = "completed_at"
                }
            }
            
            let completion = LessonCompletion(
                id: nil,
                userId: userId,
                courseId: courseId,
                lessonId: lessonId,
                completedAt: Date()
            )
            
            // Insert or update lesson completion
            try await supabase
                .from("lesson_completions")
                .upsert(completion)
                .execute()
            
            return true
        } catch {
            print("❌ Error marking lesson complete: \\(error)")
            errorMessage = "Failed to mark lesson as complete: \\(error.localizedDescription)"
            return false
        }
    }
    
    /// Update course progress based on completed lessons
    func updateCourseProgress(userId: UUID, courseId: UUID) async {
        do {
            // Fetch the course to get total lesson count
            guard let course = await fetchCourse(by: courseId) else {
                print("❌ Could not fetch course for progress update")
                return
            }
            
            // Calculate total lessons
            let totalLessons = course.modules.reduce(0) { $0 + $1.lessons.count }
            guard totalLessons > 0 else {
                print("⚠️ Course has no lessons")
                return
            }
            
            // Fetch completed lessons for this user and course
            struct LessonCompletionQuery: Codable {
                let lessonId: UUID
                
                enum CodingKeys: String, CodingKey {
                    case lessonId = "lesson_id"
                }
            }
            
            let completions: [LessonCompletionQuery] = try await supabase
                .from("lesson_completions")
                .select("lesson_id")
                .eq("user_id", value: userId.uuidString)
                .eq("course_id", value: courseId.uuidString)
                .execute()
                .value
            
            let completedCount = completions.count
            let progress = Double(completedCount) / Double(totalLessons)
            
            print("📊 Progress: \\(completedCount)/\\(totalLessons) = \\(progress)")
            
            // Update enrollment progress
            struct ProgressUpdate: Encodable {
                let progress: Double
            }
            
            try await supabase
                .from("enrollments")
                .update(ProgressUpdate(progress: progress))
                .eq("user_id", value: userId.uuidString)
                .eq("course_id", value: courseId.uuidString)
                .execute()
            
            print("✅ Progress updated successfully")
        } catch {
            print("❌ Error updating course progress: \\(error)")
            errorMessage = "Failed to update progress: \\(error.localizedDescription)"
        }
    }
}

// Helper model for enrollment
struct Enrollment: Codable {
    var id: UUID?
    var userID: UUID
    var courseID: UUID
    var enrolledAt: Date?
    var progress: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case courseID = "course_id"
        case enrolledAt = "enrolled_at"
        case progress
    }
    
    init(userID: UUID, courseID: UUID) {
        self.userID = userID
        self.courseID = courseID
        self.enrolledAt = Date()
    }
}
