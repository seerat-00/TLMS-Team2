//
//  EducatorCourseReviewsView.swift
//  TLMS-project-main
//
//  View for educators to see and manage course reviews
//

import SwiftUI

struct EducatorCourseReviewsView: View {
    let courseID: UUID
    @StateObject private var viewModel: EducatorReviewViewModel
    @State private var showReplySheet = false
    @State private var selectedReview: CourseReview?
    
    init(courseID: UUID) {
        self.courseID = courseID
        _viewModel = StateObject(wrappedValue: EducatorReviewViewModel(courseID: courseID))
    }
    
    var body: some View {
        ZStack {
            AppTheme.groupedBackground
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("Loading reviews...")
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryBlue))
            } else if viewModel.reviews.isEmpty {
                EmptyReviewsView()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Rating Overview
                        RatingOverviewCard(statistics: viewModel.statistics)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        // Filters and Sort
                        VStack(spacing: 16) {
                            // Filter by rating
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(ReviewFilterRating.allCases) { filter in
                                        FilterChip(
                                            title: filter.displayName,
                                            count: filter == .all ? viewModel.statistics.totalReviews : viewModel.statistics.count(for: filter.rawValue),
                                            isSelected: viewModel.selectedFilter == filter,
                                            action: {
                                                viewModel.updateFilter(filter)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Sort options
                            HStack {
                                Text("Sort by:")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(AppTheme.secondaryText)
                                
                                Menu {
                                    ForEach(ReviewSortOption.allCases) { option in
                                        Button(action: {
                                            viewModel.updateSort(option)
                                        }) {
                                            Label(option.rawValue, systemImage: option.icon)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(viewModel.selectedSort.rawValue)
                                            .font(.subheadline.weight(.semibold))
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                    }
                                    .foregroundColor(AppTheme.primaryBlue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.primaryBlue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        
                        // Reviews List
                        VStack(spacing: 16) {
                            if viewModel.filteredReviews.isEmpty {
                                NoReviewsForFilterView()
                                    .padding(.horizontal)
                            } else {
                                ForEach(viewModel.filteredReviews) { review in
                                    EducatorReviewCard(
                                        review: review,
                                        onReply: {
                                            selectedReview = review
                                            showReplySheet = true
                                        },
                                        onToggleVisibility: {
                                            Task {
                                                await viewModel.toggleVisibility(for: review)
                                            }
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .task {
            await viewModel.loadReviews()
        }
        .sheet(isPresented: $showReplySheet) {
            if let review = selectedReview {
                ReplyToReviewSheet(review: review, courseID: courseID)
            }
        }
    }
}

// MARK: - Rating Overview Card

struct RatingOverviewCard: View {
    let statistics: ReviewStatistics
    
    var body: some View {
        VStack(spacing: 20) {
            // Overall Rating
            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(String(format: "%.1f", statistics.averageRating))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(AppTheme.primaryText)
                    
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: Double(index) <= statistics.averageRating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(Double(index) <= statistics.averageRating ? .orange : .gray.opacity(0.3))
                        }
                    }
                    
                    Text("\(statistics.totalReviews) \(statistics.totalReviews == 1 ? "review" : "reviews")")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Divider()
                    .frame(height: 100)
                
                // Rating Distribution
                VStack(alignment: .leading, spacing: 8) {
                    ForEach((1...5).reversed(), id: \.self) { rating in
                        RatingBar(
                            rating: rating,
                            count: statistics.count(for: rating),
                            percentage: statistics.percentage(for: rating)
                        )
                    }
                }
            }
        }
        .padding()
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
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(rating)")
                .font(.caption.weight(.medium))
                .foregroundColor(AppTheme.secondaryText)
                .frame(width: 12)
            
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundColor(.orange)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.orange)
                        .frame(width: geometry.size.width * (percentage / 100), height: 6)
                }
            }
            .frame(height: 6)
            
            Text("\(count)")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text("(\(count))")
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : AppTheme.primaryBlue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? AppTheme.primaryBlue : AppTheme.primaryBlue.opacity(0.1))
            .cornerRadius(20)
        }
    }
}

// MARK: - Educator Review Card

struct EducatorReviewCard: View {
    let review: CourseReview
    let onReply: () -> Void
    let onToggleVisibility: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Reviewer info
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.reviewerName)
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= review.rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(index <= review.rating ? .orange : .gray.opacity(0.3))
                        }
                        
                        Text("•")
                            .foregroundColor(AppTheme.secondaryText)
                        
                        Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                
                Spacer()
                
                // Visibility toggle
                Button(action: onToggleVisibility) {
                    Image(systemName: review.isVisible ? "eye.fill" : "eye.slash.fill")
                        .font(.subheadline)
                        .foregroundColor(review.isVisible ? AppTheme.primaryBlue : .red)
                        .frame(width: 32, height: 32)
                        .background(review.isVisible ? AppTheme.primaryBlue.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Review text
            if let text = review.reviewText, !text.isEmpty {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Visibility status
            if !review.isVisible {
                HStack(spacing: 4) {
                    Image(systemName: "eye.slash")
                        .font(.caption2)
                    Text("Hidden from students")
                        .font(.caption.italic())
                }
                .foregroundColor(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Reply button
            Button(action: onReply) {
                HStack(spacing: 6) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.caption)
                    Text("Reply")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundColor(AppTheme.primaryBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.primaryBlue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Reply Sheet

struct ReplyToReviewSheet: View {
    let review: CourseReview
    let courseID: UUID
    @Environment(\.dismiss) var dismiss
    @State private var replyText = ""
    @State private var isSending = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.groupedBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Original review
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Replying to:")
                            .font(.caption.weight(.medium))
                            .foregroundColor(AppTheme.secondaryText)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(review.reviewerName)
                                    .font(.subheadline.weight(.semibold))
                                
                                Spacer()
                                
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { index in
                                        Image(systemName: index <= review.rating ? "star.fill" : "star")
                                            .font(.system(size: 10))
                                            .foregroundColor(index <= review.rating ? .orange : .gray.opacity(0.3))
                                    }
                                }
                            }
                            
                            if let text = review.reviewText, !text.isEmpty {
                                Text(text)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                                    .lineLimit(3)
                            }
                        }
                        .padding()
                        .background(AppTheme.secondaryGroupedBackground)
                        .cornerRadius(8)
                    }
                    
                    // Reply input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Reply")
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryText)
                        
                        ZStack(alignment: .topLeading) {
                            if replyText.isEmpty {
                                Text("Thank you for your feedback...")
                                    .foregroundColor(.gray.opacity(0.6))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                            
                            TextEditor(text: $replyText)
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                        }
                        .background(AppTheme.secondaryGroupedBackground)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Reply to Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        sendReply()
                    }
                    .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func sendReply() {
        isSending = true
        // TODO: Implement reply functionality with backend
        // For now, just dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

// MARK: - Empty States

struct EmptyReviewsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.bubble")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.secondaryText.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Reviews Yet")
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.primaryText)
                
                Text("When students complete your course, their reviews will appear here.")
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NoReviewsForFilterView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.secondaryText.opacity(0.5))
            
            VStack(spacing: 4) {
                Text("No Reviews Match Filter")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Text("Try selecting a different filter option")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(12)
    }
}
