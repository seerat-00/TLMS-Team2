//
//  AdminCourseValueViewModel.swift
//  TLMS-project-main
//
//  ViewModel for monitoring course value (ratings, price, enrollment)
//

import Foundation
import Combine
import SwiftUI

enum AdminCourseSortOption: String, CaseIterable, Identifiable {
    case defaultSort = "Default"
    case lowestRating = "Lowest Rating"
    case highestRating = "Highest Rating"
    case highestPrice = "Highest Price"
    case mostStudents = "Most Students"
    
    var id: String { rawValue }
}

@MainActor
class AdminCourseValueViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var sortOption: AdminCourseSortOption = .lowestRating {
        didSet {
            sortCourses()
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let courseService = CourseService()
    
    func loadCourses() async {
        isLoading = true
        errorMessage = nil
        
        // Fetch real published courses from Supabase
        let fetchedCourses = await courseService.fetchPublishedCourses()
        
        // MOCK DATA AUGMENTATION
        // Since backend doesn't have rating/price/enrolledCount yet, we mock them for the demo.
        // In a real app, these would come from the DB.
        
        var augmentedCourses: [Course] = []
        
        for var course in fetchedCourses {
            // Only add mock data if missing
            if course.rating == nil {
                // Random rating between 1.0 and 5.0, weighted towards higher ratings
                let randomRating = Double.random(in: 2.5...5.0)
                course.rating = (randomRating * 10).rounded() / 10 // Round to 1 decimal
            }
            
            if course.price == nil {
                // Random price between 0 (free) and 199.99
                let isFree = Bool.random() && Bool.random() // 25% chance of free
                if isFree {
                    course.price = 0
                } else {
                    let randomPrice = Double.random(in: 9.99...199.99)
                    // Round to nice price
                    course.price = (randomPrice * 100).rounded() / 100
                }
            }
            
            if course.enrolledCount == nil {
                // Random count
                course.enrolledCount = Int.random(in: 0...5000)
            }
            
            augmentedCourses.append(course)
        }
        
        self.courses = augmentedCourses
        sortCourses()
        isLoading = false
    }
    
    private func sortCourses() {
        switch sortOption {
        case .defaultSort:
            // Sort by title
            courses.sort { $0.title < $1.title }
        case .lowestRating:
            courses.sort { ($0.rating ?? 5.0) < ($1.rating ?? 5.0) }
        case .highestRating:
            courses.sort { ($0.rating ?? 0.0) > ($1.rating ?? 0.0) }
        case .highestPrice:
            courses.sort { ($0.price ?? 0.0) > ($1.price ?? 0.0) }
        case .mostStudents:
            courses.sort { ($0.enrolledCount ?? 0) > ($1.enrolledCount ?? 0) }
        }
    }
    
    func refresh() {
        Task {
            await loadCourses()
        }
    }
    
    func removeCourse(_ course: Course, reason: String) async {
        isLoading = true
        
        // 1. Update DB
        let success = await courseService.updateCourseStatus(courseID: course.id, status: .removed, reason: reason)
        
        if success {
            // 2. Mock Email
            _ = await EmailService.shared.sendRemovalNotification(
                to: "educator@example.com", // Mock email receipt
                courseTitle: course.title,
                reason: reason
            )
            
            // 3. Update UI
            if let index = courses.firstIndex(where: { $0.id == course.id }) {
                courses.remove(at: index)
            }
        } else {
            errorMessage = "Failed to remove course. Please try again."
        }
        
        isLoading = false
    }
}
