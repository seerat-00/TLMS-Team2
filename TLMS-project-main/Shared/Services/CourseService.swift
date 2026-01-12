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
            let courses: [Course] = try await supabase
                .from("courses")
                .select()
                .eq("status", value: "published")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("DEBUG: Fetched \(courses.count) published courses")
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
    
    func updateCourseStatus(courseID: UUID, status: CourseStatus) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("courses")
                .update(["status": status.rawValue])
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
                .eq("user_id", value: userID.uuidString)
                .execute()
                .value
            
            let courseIDs = enrollments.map { $0.courseID }
            
            if courseIDs.isEmpty {
                return []
            }
            
            // 2. Fetch courses matching IDs
            // Supabase "in" filter expects a comma-separated string of values in parens? 
            // Or simpler to just fetch all and filter client side if list is small?
            // Better: Use `in` filter correctly.
            // Supabase Swift client usage for `in`: .in("id", value: [ids])
            
            let courses: [Course] = try await supabase
                .from("courses")
                .select()
                .in("id", value: courseIDs.map { $0.uuidString })
                .execute()
                .value
            
            return courses
        } catch {
            errorMessage = "Failed to fetch enrolled courses: \(error.localizedDescription)"
            return []
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
    }
}
