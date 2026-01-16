//
//  QuestionAnalyticsCard.swift
//  TLMS-project-main
//
//  Reusable component for displaying question-level analytics
//

import SwiftUI

struct QuestionAnalyticsCard: View {
    let questionNumber: Int
    let analytics: QuestionAnalytics
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                // Question Number Badge
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryBlue.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Text("\(questionNumber)")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.primaryBlue)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Question Text
                    Text(analytics.questionText)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.primaryText)
                        .lineLimit(isExpanded ? nil : 2)
                        .multilineTextAlignment(.leading)
                    
                    // Question Type Badge
                    HStack(spacing: 4) {
                        Image(systemName: analytics.questionType.icon)
                            .font(.caption2)
                        Text(analytics.questionType.displayName)
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundColor(AppTheme.primaryBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.primaryBlue.opacity(0.1))
                    .cornerRadius(6)
                }
                
                Spacer()
                
                // Expand/Collapse Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            
            Divider()
            
            // Stats Grid
            HStack(spacing: 16) {
                // Success Rate
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(analytics.difficultyColor)
                        
                        Text(String(format: "%.0f%%", analytics.successRate))
                            .font(.headline)
                            .foregroundColor(analytics.difficultyColor)
                    }
                    
                    Text("Success Rate")
                        .font(.caption2)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Divider()
                    .frame(height: 30)
                
                // Difficulty
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption)
                            .foregroundColor(analytics.difficultyColor)
                        
                        Text(analytics.difficulty)
                            .font(.headline)
                            .foregroundColor(analytics.difficultyColor)
                    }
                    
                    Text("Difficulty")
                        .font(.caption2)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Divider()
                    .frame(height: 30)
                
                // Average Points
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f/%d", analytics.averagePoints, analytics.maxPoints))
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text("Avg Points")
                        .font(.caption2)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            
            // Expanded Details
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    // Attempts Info
                    HStack(spacing: 16) {
                        StatBadge(
                            icon: "person.2.fill",
                            label: "Total Attempts",
                            value: "\(analytics.totalAttempts)"
                        )
                        
                        StatBadge(
                            icon: "checkmark.circle.fill",
                            label: "Correct",
                            value: "\(analytics.correctAttempts)",
                            color: AppTheme.successGreen
                        )
                        
                        StatBadge(
                            icon: "xmark.circle.fill",
                            label: "Incorrect",
                            value: "\(analytics.totalAttempts - analytics.correctAttempts)",
                            color: AppTheme.errorRed
                        )
                    }
                    
                    // Common Wrong Answers (for MCQ)
                    if !analytics.commonWrongAnswers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Most Common Wrong Answers")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AppTheme.primaryText)
                            
                            ForEach(analytics.commonWrongAnswers.indices, id: \.self) { index in
                                let wrongAnswer = analytics.commonWrongAnswers[index]
                                HStack(spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(.caption2)
                                        .foregroundColor(AppTheme.secondaryText)
                                    
                                    Text(wrongAnswer.option)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.primaryText)
                                        .lineLimit(2)
                                    
                                    Spacer()
                                    
                                    Text("\(wrongAnswer.count) times")
                                        .font(.caption2)
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(AppTheme.errorRed.opacity(0.05))
                                .cornerRadius(6)
                            }
                        }
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

struct StatBadge: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = AppTheme.primaryBlue
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.caption.bold())
                    .foregroundColor(color)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
