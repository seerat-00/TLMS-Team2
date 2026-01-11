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
}
