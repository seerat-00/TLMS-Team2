//
//  RatingDistributionView.swift
//  TLMS-project-main
//
//  Visual component showing rating breakdown with bar chart
//

import SwiftUI

struct RatingDistributionView: View {
    let statistics: ReviewStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top, spacing: 16) {
                // Large average rating
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", statistics.averageRating))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(AppTheme.primaryText)
                    
                    // Stars
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= Int(statistics.averageRating.rounded()) ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text("\(statistics.totalReviews) review\(statistics.totalReviews == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(width: 100)
                
                // Distribution bars
                VStack(spacing: 8) {
                    ForEach([5, 4, 3, 2, 1], id: \.self) { rating in
                        RatingBar(
                            rating: rating,
                            count: statistics.count(for: rating),
                            percentage: statistics.percentage(for: rating),
                            totalReviews: statistics.totalReviews
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Rating Bar

struct RatingBar: View {
    let rating: Int
    let count: Int
    let percentage: Double
    let totalReviews: Int
    
    var barColor: Color {
        switch rating {
        case 5: return AppTheme.successGreen
        case 4: return Color.green.opacity(0.7)
        case 3: return .orange
        case 2: return Color.orange.opacity(0.7)
        case 1: return .red
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Rating label
            Text("\(rating)★")
                .font(.caption.weight(.medium))
                .foregroundColor(AppTheme.secondaryText)
                .frame(width: 30, alignment: .leading)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.primaryText.opacity(0.1))
                        .frame(height: 8)
                    
                    // Filled portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: totalReviews > 0 ? geometry.size.width * (percentage / 100.0) : 0, height: 8)
                }
            }
            .frame(height: 8)
            
            // Count
            Text("\(count)")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // With reviews
        RatingDistributionView(statistics: ReviewStatistics(
            averageRating: 4.3,
            totalReviews: 127,
            ratingDistribution: [
                5: 68,
                4: 32,
                3: 15,
                2: 8,
                1: 4
            ]
        ))
        
        // No reviews
        RatingDistributionView(statistics: ReviewStatistics())
    }
    .padding()
    .background(AppTheme.groupedBackground)
}
