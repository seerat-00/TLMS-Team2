//
//  QuizResultsListView.swift
//  TLMS-project-main
//
//  Main view showing all quizzes with results for an educator
//

import SwiftUI

struct QuizResultsListView: View {
    let educatorID: UUID
    @StateObject private var viewModel = QuizResultsViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            AppTheme.groupedBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Search and Filter Section
                    VStack(spacing: 12) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppTheme.secondaryText)
                            
                            TextField("Search quizzes...", text: $viewModel.searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(12)
                        .background(AppTheme.secondaryGroupedBackground)
                        .cornerRadius(AppTheme.cornerRadius)
                        
                        // Course Filter
                        if viewModel.availableCourses.count > 1 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.availableCourses, id: \.self) { course in
                                        FilterChip(
                                            title: course,
                                            isSelected: viewModel.selectedCourseFilter == course
                                        ) {
                                            viewModel.selectedCourseFilter = course
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Results List
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if let errorMessage = viewModel.errorMessage {
                        ErrorView(message: errorMessage) {
                            Task {
                                await viewModel.refresh(educatorID: educatorID)
                            }
                        }
                    } else if viewModel.filteredResults.isEmpty {
                        EmptyQuizResultsView(hasResults: !viewModel.quizResultsSummaries.isEmpty)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredResults) { summary in
                                NavigationLink(destination: QuizAnalyticsView(quizID: summary.quizID)) {
                                    QuizResultCard(summary: summary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Quiz Results")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await viewModel.refresh(educatorID: educatorID)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AppTheme.primaryBlue)
                }
            }
        }
        .task {
            await viewModel.loadQuizResults(educatorID: educatorID)
        }
    }
}

// MARK: - Quiz Result Card

struct QuizResultCard: View {
    let summary: QuizResultsSummary
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                // Quiz Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.primaryBlue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "doc.text.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.primaryBlue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.quizTitle)
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(summary.courseTitle)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Divider()
            
            // Stats Grid
            HStack(spacing: 16) {
                StatItem(
                    icon: "person.2.fill",
                    label: "Submissions",
                    value: "\(summary.totalSubmissions)"
                )
                
                Divider()
                    .frame(height: 30)
                
                StatItem(
                    icon: "chart.bar.fill",
                    label: "Avg Score",
                    value: String(format: "%.0f%%", summary.averagePercentage),
                    color: summary.performanceColor
                )
                
                if summary.needsGrading > 0 {
                    Divider()
                        .frame(height: 30)
                    
                    StatItem(
                        icon: "exclamationmark.circle.fill",
                        label: "Needs Grading",
                        value: "\(summary.needsGrading)",
                        color: AppTheme.warningOrange
                    )
                }
            }
            
            // Last Submission
            if let lastSubmission = summary.lastSubmissionDate {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                    Text("Last submission: \(lastSubmission.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                }
                .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding(16)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : AppTheme.primaryBlue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.primaryBlue : AppTheme.secondaryGroupedBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.primaryBlue, lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = AppTheme.primaryText
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(color)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyQuizResultsView: View {
    let hasResults: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasResults ? "magnifyingglass" : "chart.bar.doc.horizontal")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.secondaryText.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(hasResults ? "No results found" : "No quiz results yet")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText)
                
                Text(hasResults ? "Try adjusting your search or filters" : "Quiz results will appear here once learners start taking your quizzes")
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.errorRed)
            
            Text("Error")
                .font(.title3.weight(.semibold))
                .foregroundColor(AppTheme.primaryText)
            
            Text(message)
                .font(.body)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: retry) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.primaryBlue)
                    .cornerRadius(10)
            }
        }
        .padding(.vertical, 60)
    }
}
