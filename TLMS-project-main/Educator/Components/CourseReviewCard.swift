//
//  CourseReviewCard.swift
//  TLMS-project-main
//
//  Reusable component for displaying individual course reviews
//

import SwiftUI

struct CourseReviewCard: View {
    let review: CourseReview
    let educatorReply: EducatorReply?
    let onReply: (() -> Void)?
    let onHide: (() -> Void)?
    
    @State private var isExpanded = false
    @Environment(\.colorScheme) var colorScheme
    
    private let maxPreviewLength = 150
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Learner info and rating
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryBlue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Text(review.reviewerName.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryBlue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.reviewerName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Spacer()
                
                // Star rating
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= review.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(index <= review.rating ? .orange : .gray.opacity(0.3))
                    }
                }
            }
            
            // Review text
            if let reviewText = review.reviewText, !reviewText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if reviewText.count > maxPreviewLength && !isExpanded {
                        Text(reviewText.prefix(maxPreviewLength) + "...")
                            .font(.body)
                            .foregroundColor(AppTheme.primaryText)
                        
                        Button(action: { isExpanded = true }) {
                            Text("Read more")
                                .font(.caption.weight(.medium))
                                .foregroundColor(AppTheme.primaryBlue)
                        }
                    } else {
                        Text(reviewText)
                            .font(.body)
                            .foregroundColor(AppTheme.primaryText)
                        
                        if reviewText.count > maxPreviewLength {
                            Button(action: { isExpanded = false }) {
                                Text("Show less")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(AppTheme.primaryBlue)
                            }
                        }
                    }
                }
            }
            
            // Educator reply section
            if let reply = educatorReply {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.primaryBlue)
                        
                        Text("Educator Response")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.primaryBlue)
                        
                        Spacer()
                        
                        Text(reply.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Text(reply.replyText)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.primaryText)
                        .padding(12)
                        .background(AppTheme.primaryBlue.opacity(0.05))
                        .cornerRadius(8)
                }
            }
            
            // Action buttons
            HStack(spacing: 16) {
                if let onReply = onReply, educatorReply == nil {
                    Button(action: onReply) {
                        Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
                            .font(.caption.weight(.medium))
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                }
                
                if let onHide = onHide {
                    Button(action: onHide) {
                        Label(review.isVisible ? "Hide" : "Show", systemImage: review.isVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Review with text
        CourseReviewCard(
            review: CourseReview(
                id: UUID(),
                courseID: UUID(),
                userID: UUID(),
                rating: 5,
                reviewText: "This course was absolutely fantastic! I learned so much and the instructor explained everything clearly. Highly recommend to anyone looking to improve their skills.",
                isVisible: true,
                createdAt: Date()
            ),
            educatorReply: nil,
            onReply: {},
            onHide: {}
        )
        
        // Review with educator reply
        CourseReviewCard(
            review: CourseReview(
                id: UUID(),
                courseID: UUID(),
                userID: UUID(),
                rating: 4,
                reviewText: "Great content overall, but could use more examples.",
                isVisible: true,
                createdAt: Date()
            ),
            educatorReply: EducatorReply(
                reviewID: UUID(),
                educatorID: UUID(),
                replyText: "Thank you for your feedback! I'll be adding more practical examples in the next update."
            ),
            onReply: nil,
            onHide: {}
        )
    }
    .padding()
    .background(AppTheme.groupedBackground)
}
