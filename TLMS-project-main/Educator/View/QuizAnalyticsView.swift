//
//  QuizAnalyticsView.swift
//  TLMS-project-main
//
//  Detailed analytics view for a specific quiz
//

import SwiftUI
import Charts

struct QuizAnalyticsView: View {
    let quizID: UUID
    @StateObject private var viewModel = QuizAnalyticsViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            AppTheme.groupedBackground
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage) {
                    Task {
                        await viewModel.loadQuizAnalytics(quizID: quizID)
                    }
                }
            } else if let analytics = viewModel.analytics {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Overview Stats
                        overviewSection(analytics: analytics)
                        
                        // Performance Distribution Chart
                        if #available(iOS 16.0, *) {
                            performanceDistributionChart
                        }
                        
                        // AI Insights Section
                        aiInsightsSection
                        
                        // Question Analysis
                        questionAnalysisSection(analytics: analytics)
                        
                        // Top Performers
                        if !viewModel.topPerformers.isEmpty {
                            topPerformersSection
                        }
                        
                        // Struggling Learners
                        if !viewModel.strugglingLearners.isEmpty {
                            strugglingLearnersSection
                        }
                        
                        // Needs Grading
                        if !viewModel.needsGrading.isEmpty {
                            needsGradingSection
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle(viewModel.quiz?.title ?? "Quiz Analytics")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadQuizAnalytics(quizID: quizID)
        }
        .sheet(isPresented: $viewModel.showingLearnerPerformance) {
            if let submission = viewModel.selectedSubmission, let quiz = viewModel.quiz {
                NavigationView {
                    LearnerPerformanceView(quiz: quiz, submission: submission)
                }
            }
        }
    }
    
    // MARK: - Overview Section
    
    private func overviewSection(analytics: QuizAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.title2.bold())
                .foregroundColor(AppTheme.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                OverviewStatCard(
                    icon: "person.2.fill",
                    title: "Total Submissions",
                    value: "\(analytics.totalSubmissions)",
                    color: AppTheme.primaryBlue
                )
                
                OverviewStatCard(
                    icon: "chart.bar.fill",
                    title: "Average Score",
                    value: String(format: "%.1f%%", analytics.averagePercentage),
                    color: analytics.averagePercentage >= 70 ? AppTheme.successGreen : AppTheme.warningOrange
                )
                
                OverviewStatCard(
                    icon: "arrow.up.circle.fill",
                    title: "Highest Score",
                    value: "\(analytics.highestScore)/\(analytics.totalPoints)",
                    color: AppTheme.successGreen
                )
                
                OverviewStatCard(
                    icon: "arrow.down.circle.fill",
                    title: "Lowest Score",
                    value: "\(analytics.lowestScore)/\(analytics.totalPoints)",
                    color: AppTheme.errorRed
                )
                
                if let avgTime = analytics.averageTimeSeconds {
                    OverviewStatCard(
                        icon: "clock.fill",
                        title: "Avg Time",
                        value: formatTime(avgTime),
                        color: .purple
                    )
                }
                
                OverviewStatCard(
                    icon: "checkmark.circle.fill",
                    title: "Completion Rate",
                    value: String(format: "%.0f%%", analytics.completionRate),
                    color: AppTheme.successGreen
                )
            }
        }
    }
    
    // MARK: - Performance Distribution Chart
    
    @available(iOS 16.0, *)
    private var performanceDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Distribution")
                .font(.title2.bold())
                .foregroundColor(AppTheme.primaryText)
            
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.scoreDistribution.contains(where: { $0.count > 0 }) {
                    Chart(viewModel.scoreDistribution) { data in
                        BarMark(
                            x: .value("Range", data.range),
                            y: .value("Count", data.count)
                        )
                        .foregroundStyle(data.color.gradient)
                        .cornerRadius(6)
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    
                    // Legend
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(viewModel.scoreDistribution.filter { $0.count > 0 }) { data in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(data.color)
                                    .frame(width: 8, height: 8)
                                
                                Text("\(data.range): \(data.count)")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } else {
                    Text("No data available")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                }
            }
            .padding(16)
            .background(AppTheme.secondaryGroupedBackground)
            .cornerRadius(AppTheme.cornerRadius)
        }
    }
    
    // MARK: - AI Insights Section
    
    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI Insights")
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                if viewModel.isLoadingInsights {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let insights = viewModel.aiInsights {
                AIInsightsCard(insights: insights)
            } else if viewModel.isLoadingInsights {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Generating insights...")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(AppTheme.secondaryGroupedBackground)
                .cornerRadius(AppTheme.cornerRadius)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.largeTitle)
                        .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                    
                    Text("AI insights unavailable")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    Button(action: {
                        Task {
                            await viewModel.generateAIInsights()
                        }
                    }) {
                        Text("Generate Insights")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.purple)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(AppTheme.secondaryGroupedBackground)
                .cornerRadius(AppTheme.cornerRadius)
            }
        }
    }
    
    // MARK: - Question Analysis Section
    
    private func questionAnalysisSection(analytics: QuizAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Question Analysis")
                .font(.title2.bold())
                .foregroundColor(AppTheme.primaryText)
            
            if analytics.questionAnalytics.isEmpty {
                Text("No question data available")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
                    .background(AppTheme.secondaryGroupedBackground)
                    .cornerRadius(AppTheme.cornerRadius)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(analytics.questionAnalytics.enumerated()), id: \.element.id) { index, question in
                        QuestionAnalyticsCard(questionNumber: index + 1, analytics: question)
                    }
                }
            }
        }
    }
    
    // MARK: - Top Performers Section
    
    private var topPerformersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("Top Performers")
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.primaryText)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.topPerformers) { performance in
                    Button(action: {
                        viewModel.selectSubmission(performance.submission)
                    }) {
                        LearnerPerformanceCard(performance: performance, showRank: true)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Struggling Learners Section
    
    private var strugglingLearnersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.warningOrange)
                Text("Needs Attention")
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.primaryText)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.strugglingLearners) { performance in
                    Button(action: {
                        viewModel.selectSubmission(performance.submission)
                    }) {
                        LearnerPerformanceCard(performance: performance, showRank: false)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Needs Grading Section
    
    private var needsGradingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .foregroundColor(AppTheme.primaryBlue)
                Text("Pending Grading")
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.primaryText)
            }
            
            Text("\(viewModel.needsGrading.count) submission\(viewModel.needsGrading.count == 1 ? "" : "s") waiting for manual grading")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.needsGrading) { submission in
                    Button(action: {
                        viewModel.selectSubmission(submission)
                    }) {
                        PendingGradingCard(submission: submission)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Supporting Views

struct OverviewStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(AppTheme.primaryText)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct LearnerPerformanceCard: View {
    let performance: LearnerPerformance
    let showRank: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank or Icon
            if showRank, let rank = performance.rank {
                ZStack {
                    Circle()
                        .fill(rankColor(rank).opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Text("#\(rank)")
                        .font(.headline)
                        .foregroundColor(rankColor(rank))
                }
            } else {
                ZStack {
                    Circle()
                        .fill(AppTheme.errorRed.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "person.fill")
                        .foregroundColor(AppTheme.errorRed)
                }
            }
            
            // Learner Info
            VStack(alignment: .leading, spacing: 4) {
                Text(performance.learnerName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)
                
                Text(performance.learnerEmail)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(performance.submission.score)/\(performance.submission.totalPoints)")
                    .font(.headline)
                    .foregroundColor(performance.submission.gradeColor)
                
                Text(String(format: "%.0f%%", performance.submission.percentageScore))
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(12)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return AppTheme.primaryBlue
        }
    }
}

struct PendingGradingCard: View {
    let submission: QuizSubmission
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .foregroundColor(AppTheme.warningOrange)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(submission.learnerName ?? "Unknown Learner")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)
                
                Text("Submitted \(submission.submittedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(12)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
