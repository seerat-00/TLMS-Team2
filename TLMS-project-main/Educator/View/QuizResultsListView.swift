//
//  QuizResultsListView.swift
//  TLMS-project-main
//
//  Quiz Results List View for Educators
//

import SwiftUI
import Combine

struct QuizResultsListView: View {
    let educatorID: UUID
    @StateObject private var viewModel = QuizResultsViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.groupedBackground
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("Loading quiz results...")
                    .padding()
            } else if viewModel.quizResults.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.quizResults) { result in
                            QuizResultCard(result: result)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Quiz Submissions")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadQuizResults(educatorID: educatorID)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 50))
                .foregroundStyle(AppTheme.secondaryText.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Quiz Submissions Yet")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText)
                
                Text("Quiz submissions from learners will appear here")
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Quiz Result Card

struct QuizResultCard: View {
    let result: QuizResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.learnerName)
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(result.courseName)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Spacer()
                
                // Score badge
                VStack(spacing: 2) {
                    Text("\(result.score)%")
                        .font(.title3.bold())
                        .foregroundColor(scoreColor)
                    
                    Text("Score")
                        .font(.caption2)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(scoreColor.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Details
            HStack(spacing: 16) {
                Label("\(result.correctAnswers)/\(result.totalQuestions)", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                
                Label(result.submittedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding(16)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var scoreColor: Color {
        if result.score >= 80 {
            return AppTheme.successGreen
        } else if result.score >= 60 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Quiz Results ViewModel

@MainActor
class QuizResultsViewModel: ObservableObject {
    @Published var quizResults: [QuizResult] = []
    @Published var isLoading = false
    
    func loadQuizResults(educatorID: UUID) async {
        isLoading = true
        
        // TODO: Replace with actual API call
        // For now, using empty array
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        quizResults = []
        isLoading = false
    }
}

// MARK: - Quiz Result Model

struct QuizResult: Identifiable {
    let id: UUID
    let learnerName: String
    let courseName: String
    let score: Int
    let correctAnswers: Int
    let totalQuestions: Int
    let submittedAt: Date
}

#Preview {
    NavigationView {
        QuizResultsListView(educatorID: UUID())
    }
}
