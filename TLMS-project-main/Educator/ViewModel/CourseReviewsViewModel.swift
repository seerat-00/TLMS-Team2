//
//  CourseReviewsViewModel.swift
//  TLMS-project-main
//
//  ViewModel for managing course reviews with filtering and sorting
//

import SwiftUI
import Combine

@MainActor
class CourseReviewsViewModel: ObservableObject {
    @Published var reviews: [CourseReview] = []
    @Published var filteredReviews: [CourseReview] = []
    @Published var statistics: ReviewStatistics = ReviewStatistics()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filters and sorting
    @Published var sortOption: ReviewSortOption = .newest {
        didSet { applyFiltersAndSort() }
    }
    @Published var filterRating: ReviewFilterRating = .all {
        didSet { applyFiltersAndSort() }
    }
    @Published var searchText: String = "" {
        didSet { applyFiltersAndSort() }
    }
    
    // Educator replies (in-memory for now, would come from backend)
    @Published var educatorReplies: [UUID: EducatorReply] = [:]
    
    private let reviewService = ReviewService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Load Reviews
    
    func loadReviews(courseID: UUID) async {
        isLoading = true
        errorMessage = nil
        
        let fetchedReviews = await reviewService.fetchReviews(for: courseID)
        
        self.reviews = fetchedReviews
        self.statistics = ReviewStatistics.calculate(from: fetchedReviews)
        
        applyFiltersAndSort()
        isLoading = false
    }
    
    // MARK: - Filtering and Sorting
    
    private func applyFiltersAndSort() {
        var result = reviews
        
        // Apply rating filter
        if filterRating != .all {
            result = result.filter { $0.rating == filterRating.rawValue }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { review in
                if let text = review.reviewText {
                    return text.localizedCaseInsensitiveContains(searchText) ||
                           review.reviewerName.localizedCaseInsensitiveContains(searchText)
                }
                return review.reviewerName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sorting
        switch sortOption {
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
    
    // MARK: - Review Actions
    
    func toggleReviewVisibility(_ review: CourseReview) async -> Bool {
        let success = await reviewService.toggleReviewVisibility(
            reviewID: review.id,
            isVisible: !review.isVisible
        )
        
        if success {
            // Update local copy
            if let index = reviews.firstIndex(where: { $0.id == review.id }) {
                reviews[index] = CourseReview(
                    id: review.id,
                    courseID: review.courseID,
                    userID: review.userID,
                    rating: review.rating,
                    reviewText: review.reviewText,
                    isVisible: !review.isVisible,
                    createdAt: review.createdAt
                )
            }
            applyFiltersAndSort()
        }
        
        return success
    }
    
    func submitReply(reviewID: UUID, replyText: String, educatorID: UUID) async -> Bool {
        // For now, store in memory
        // In production, this would call a backend API
        let reply = EducatorReply(
            reviewID: reviewID,
            educatorID: educatorID,
            replyText: replyText
        )
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        educatorReplies[reviewID] = reply
        return true
    }
    
    func getReply(for reviewID: UUID) -> EducatorReply? {
        return educatorReplies[reviewID]
    }
}
