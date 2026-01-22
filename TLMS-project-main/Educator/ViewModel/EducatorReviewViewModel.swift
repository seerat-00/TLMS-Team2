//
//  EducatorReviewViewModel.swift
//  TLMS-project-main
//
//  ViewModel for managing educator course reviews
//

import Foundation
import SwiftUI
import Combine

@MainActor
class EducatorReviewViewModel: ObservableObject {
    @Published var reviews: [CourseReview] = []
    @Published var filteredReviews: [CourseReview] = []
    @Published var statistics: ReviewStatistics = ReviewStatistics()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var selectedFilter: ReviewFilterRating = .all
    @Published var selectedSort: ReviewSortOption = .newest
    
    private let reviewService = ReviewService()
    private let courseID: UUID
    
    init(courseID: UUID) {
        self.courseID = courseID
    }
    
    // MARK: - Load Reviews
    
    func loadReviews() async {
        isLoading = true
        errorMessage = nil
        
        reviews = await reviewService.fetchReviews(for: courseID)
        statistics = ReviewStatistics.calculate(from: reviews)
        applyFiltersAndSort()
        
        isLoading = false
    }
    
    // MARK: - Filter and Sort
    
    func applyFiltersAndSort() {
        var result = reviews
        
        // Apply filter
        if selectedFilter != .all {
            result = result.filter { $0.rating == selectedFilter.rawValue }
        }
        
        // Apply sort
        switch selectedSort {
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            result.sort { $0.createdAt < $1.createdAt }
        case .highestRating:
            result.sort { $0.rating > $1.rating }
        case .lowestRating:
            result.sort { $0.rating < $1.rating }
        }
        
        filteredReviews = result
    }
    
    func updateFilter(_ filter: ReviewFilterRating) {
        selectedFilter = filter
        applyFiltersAndSort()
    }
    
    func updateSort(_ sort: ReviewSortOption) {
        selectedSort = sort
        applyFiltersAndSort()
    }
    
    // MARK: - Moderation
    
    func toggleVisibility(for review: CourseReview) async {
        let newVisibility = !review.isVisible
        let success = await reviewService.toggleReviewVisibility(
            reviewID: review.id,
            isVisible: newVisibility
        )
        
        if success {
            await loadReviews()
        }
    }
}
