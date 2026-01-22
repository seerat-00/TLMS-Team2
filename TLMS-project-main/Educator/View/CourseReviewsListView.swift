//
//  CourseReviewsListView.swift
//  TLMS-project-main
//
//  Comprehensive view for displaying and managing course reviews
//

import SwiftUI

struct CourseReviewsListView: View {
    let courseID: UUID
    let courseTitle: String
    let educatorID: UUID
    
    @StateObject private var viewModel = CourseReviewsViewModel()
    @State private var showReplySheet = false
    @State private var selectedReview: CourseReview?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.groupedBackground
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("Loading reviews...")
            } else if viewModel.statistics.totalReviews == 0 {
                // Show prominent empty state when no reviews exist at all
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.primaryBlue.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "star.bubble")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.primaryBlue.opacity(0.6))
                    }
                    
                    // Text content
                    VStack(spacing: 12) {
                        Text("No Reviews Yet")
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("Reviews from learners will appear here once they complete and rate your course")
                            .font(.body)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Info card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.orange)
                            Text("How to get reviews")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppTheme.primaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(icon: "checkmark.circle.fill", text: "Publish your course")
                            InfoRow(icon: "person.2.fill", text: "Learners enroll and complete it")
                            InfoRow(icon: "star.fill", text: "They rate and review your content")
                        }
                    }
                    .padding(16)
                    .background(AppTheme.secondaryGroupedBackground)
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Rating statistics
                        RatingDistributionView(statistics: viewModel.statistics)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        // Filter and sort controls
                        VStack(spacing: 12) {
                            // Search bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(AppTheme.secondaryText)
                                
                                TextField("Search reviews...", text: $viewModel.searchText)
                                    .font(.body)
                                    .foregroundColor(AppTheme.primaryText)
                                
                                if !viewModel.searchText.isEmpty {
                                    Button(action: { viewModel.searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                }
                            }
                            .padding(12)
                            .background(AppTheme.secondaryGroupedBackground)
                            .cornerRadius(10)
                            
                            // Filter chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(ReviewFilterRating.allCases) { filter in
                                        FilterChip(
                                            title: filter.displayName,
                                            isSelected: viewModel.filterRating == filter,
                                            count: filter == .all ? viewModel.statistics.totalReviews : viewModel.statistics.count(for: filter.rawValue)
                                        ) {
                                            viewModel.filterRating = filter
                                        }
                                    }
                                }
                            }
                            
                            // Sort menu
                            HStack {
                                Text("Sort by:")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(AppTheme.secondaryText)
                                
                                Menu {
                                    ForEach(ReviewSortOption.allCases) { option in
                                        Button(action: { viewModel.sortOption = option }) {
                                            Label(option.rawValue, systemImage: option.icon)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(viewModel.sortOption.rawValue)
                                            .font(.subheadline.weight(.semibold))
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                    }
                                    .foregroundColor(AppTheme.primaryBlue)
                                }
                                
                                Spacer()
                                
                                Text("\(viewModel.filteredReviews.count) review\(viewModel.filteredReviews.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Reviews list or filtered empty state
                        if viewModel.filteredReviews.isEmpty {
                            filteredEmptyStateView
                                .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.filteredReviews) { review in
                                    CourseReviewCard(
                                        review: review,
                                        educatorReply: viewModel.getReply(for: review.id),
                                        onReply: {
                                            selectedReview = review
                                            showReplySheet = true
                                        },
                                        onHide: {
                                            Task {
                                                _ = await viewModel.toggleReviewVisibility(review)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                }
            }
        }
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadReviews(courseID: courseID)
        }
        .sheet(isPresented: $showReplySheet) {
            if let review = selectedReview {
                ReviewReplySheet(
                    review: review,
                    educatorID: educatorID,
                    onSubmit: { replyText in
                        await viewModel.submitReply(
                            reviewID: review.id,
                            replyText: replyText,
                            educatorID: educatorID
                        )
                    }
                )
            }
        }
    }
    
    private var filteredEmptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.searchText.isEmpty && viewModel.filterRating == .all ? "star.bubble" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(AppTheme.secondaryText.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText)
                
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if !viewModel.searchText.isEmpty || viewModel.filterRating != .all {
                Button(action: {
                    viewModel.searchText = ""
                    viewModel.filterRating = .all
                }) {
                    Text("Clear Filters")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.primaryBlue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AppTheme.primaryBlue.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var emptyStateTitle: String {
        if !viewModel.searchText.isEmpty {
            return "No Matching Reviews"
        } else if viewModel.filterRating != .all {
            return "No \(viewModel.filterRating.displayName) Reviews"
        } else {
            return "No Reviews Yet"
        }
    }
    
    private var emptyStateMessage: String {
        if !viewModel.searchText.isEmpty {
            return "Try adjusting your search terms"
        } else if viewModel.filterRating != .all {
            return "This course hasn't received any \(viewModel.filterRating.displayName) ratings yet"
        } else {
            return "Reviews from learners will appear here once they complete and rate your course"
        }
    }
}

// MARK: - Info Row Component

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AppTheme.primaryBlue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
            
            Spacer()
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.caption)
                }
            }
            .foregroundColor(isSelected ? .white : AppTheme.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? AppTheme.primaryBlue : AppTheme.secondaryGroupedBackground)
            .cornerRadius(20)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        CourseReviewsListView(
            courseID: UUID(),
            courseTitle: "iOS Development Masterclass",
            educatorID: UUID()
        )
    }
}
