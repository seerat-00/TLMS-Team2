//
//  AIInsightsCard.swift
//  TLMS-project-main
//
//  Card component for displaying AI-generated insights
//

import SwiftUI

struct AIInsightsCard: View {
    let insights: QuizInsights
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with expand/collapse
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("AI Analysis")
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Divider()
                
                // Summary
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.fill")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Text("Summary")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.primaryText)
                    }
                    
                    Text(insights.summary)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                }
                
                // Strengths
                if !insights.strengths.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(AppTheme.successGreen)
                            Text("Strengths")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppTheme.primaryText)
                        }
                        
                        ForEach(insights.strengths.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(AppTheme.successGreen)
                                Text(insights.strengths[index])
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                                    .lineLimit(nil)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                }
                
                // Areas for Improvement
                if !insights.areasForImprovement.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(AppTheme.warningOrange)
                            Text("Areas for Improvement")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppTheme.primaryText)
                        }
                        
                        ForEach(insights.areasForImprovement.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(AppTheme.warningOrange)
                                Text(insights.areasForImprovement[index])
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                                    .lineLimit(nil)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                }
                
                // Recommendations
                if !insights.recommendations.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                            Text("Recommendations")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppTheme.primaryText)
                        }
                        
                        ForEach(insights.recommendations.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.purple)
                                Text(insights.recommendations[index])
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                                    .lineLimit(nil)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                }
                
                // Timestamp
                HStack {
                    Spacer()
                    Text("Generated \(insights.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(AppTheme.secondaryText.opacity(0.7))
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.3),
                            Color.blue.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.purple.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
