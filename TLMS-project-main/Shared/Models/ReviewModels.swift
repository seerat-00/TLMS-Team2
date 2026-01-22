//
//  ReviewModels.swift
//  TLMS-project-main
//
//  Models for review management and statistics
//

import Foundation

// MARK: - Review Sort Options

enum ReviewSortOption: String, CaseIterable, Identifiable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case highestRating = "Highest Rating"
    case lowestRating = "Lowest Rating"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .newest: return "arrow.down"
        case .oldest: return "arrow.up"
        case .highestRating: return "star.fill"
        case .lowestRating: return "star"
        }
    }
}

// MARK: - Review Filter Options

enum ReviewFilterRating: Int, CaseIterable, Identifiable {
    case all = 0
    case fiveStar = 5
    case fourStar = 4
    case threeStar = 3
    case twoStar = 2
    case oneStar = 1
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .fiveStar: return "5★"
        case .fourStar: return "4★"
        case .threeStar: return "3★"
        case .twoStar: return "2★"
        case .oneStar: return "1★"
        }
    }
}

// MARK: - Review Statistics

struct ReviewStatistics {
    let averageRating: Double
    let totalReviews: Int
    let ratingDistribution: [Int: Int] // Star rating (1-5) -> count
    
    init(averageRating: Double = 0.0, totalReviews: Int = 0, ratingDistribution: [Int: Int] = [:]) {
        self.averageRating = averageRating
        self.totalReviews = totalReviews
        self.ratingDistribution = ratingDistribution
    }
    
    // Calculate percentage for each rating
    func percentage(for rating: Int) -> Double {
        guard totalReviews > 0, let count = ratingDistribution[rating] else { return 0.0 }
        return Double(count) / Double(totalReviews) * 100.0
    }
    
    // Get count for specific rating
    func count(for rating: Int) -> Int {
        return ratingDistribution[rating] ?? 0
    }
    
    // Calculate statistics from reviews
    static func calculate(from reviews: [CourseReview]) -> ReviewStatistics {
        guard !reviews.isEmpty else {
            return ReviewStatistics()
        }
        
        let totalReviews = reviews.count
        let totalRating = reviews.reduce(0) { $0 + $1.rating }
        let averageRating = Double(totalRating) / Double(totalReviews)
        
        var distribution: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        for review in reviews {
            distribution[review.rating, default: 0] += 1
        }
        
        return ReviewStatistics(
            averageRating: averageRating,
            totalReviews: totalReviews,
            ratingDistribution: distribution
        )
    }
}

// MARK: - Educator Reply Model

struct EducatorReply: Identifiable, Codable {
    let id: UUID
    let reviewID: UUID
    let educatorID: UUID
    let replyText: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case reviewID = "review_id"
        case educatorID = "educator_id"
        case replyText = "reply_text"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), reviewID: UUID, educatorID: UUID, replyText: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.reviewID = reviewID
        self.educatorID = educatorID
        self.replyText = replyText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
