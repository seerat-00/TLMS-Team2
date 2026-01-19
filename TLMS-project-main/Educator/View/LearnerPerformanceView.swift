//
//  LearnerPerformanceView.swift
//  TLMS-project-main
//
//  Detailed view of individual learner's quiz attempt
//

import SwiftUI
import Combine

struct LearnerPerformanceView: View {
    let quiz: Quiz
    let submission: QuizSubmission
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = LearnerPerformanceViewModel()
    
    var body: some View {
        ZStack {
            AppTheme.groupedBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Learner Header
                    learnerHeaderSection
                    
                    // Score Overview
                    scoreOverviewSection
                    
                    // Question-by-Question Breakdown
                    questionBreakdownSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Submission Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(AppTheme.primaryBlue)
            }
        }
    }
    
    // MARK: - Learner Header Section
    
    private var learnerHeaderSection: some View {
        VStack(spacing: 16) {
            // Learner Avatar
            ZStack {
                Circle()
                    .fill(AppTheme.primaryBlue.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Text((submission.learnerName ?? "?").prefix(1).uppercased())
                    .font(.title.bold())
                    .foregroundColor(AppTheme.primaryBlue)
            }
            
            // Learner Info
            VStack(spacing: 6) {
                Text(submission.learnerName ?? "Unknown Learner")
                    .font(.title3.bold())
                    .foregroundColor(AppTheme.primaryText)
                
                if let email = submission.learnerEmail {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                // Submission Time
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                    Text("Submitted \(submission.submittedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                }
                .foregroundColor(AppTheme.secondaryText)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // MARK: - Score Overview Section
    
    private var scoreOverviewSection: some View {
        VStack(spacing: 16) {
            // Large Score Display
            VStack(spacing: 8) {
                Text("\(submission.score)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(submission.gradeColor)
                
                Text("out of \(submission.totalPoints) points")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                
                // Grade Badge
                Text(submission.grade)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(submission.gradeColor)
                    .cornerRadius(20)
            }
            .padding(.vertical, 20)
            
            Divider()
            
            // Stats Grid
            HStack(spacing: 16) {
                ScoreStatItem(
                    icon: "percent",
                    label: "Percentage",
                    value: String(format: "%.1f%%", submission.percentageScore)
                )
                
                Divider()
                    .frame(height: 40)
                
                ScoreStatItem(
                    icon: "checkmark.circle.fill",
                    label: "Correct",
                    value: "\(submission.answers.filter { $0.isCorrect == true }.count)/\(submission.answers.count)",
                    color: AppTheme.successGreen
                )
                
                if let timeSpent = submission.timeSpentSeconds {
                    Divider()
                        .frame(height: 40)
                    
                    ScoreStatItem(
                        icon: "clock.fill",
                        label: "Time Spent",
                        value: formatTime(timeSpent),
                        color: .purple
                    )
                }
            }
            .padding(.bottom, 8)
            
            // Status Badge
            HStack(spacing: 6) {
                Image(systemName: submission.status.icon)
                    .font(.caption)
                Text(submission.status.displayName)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(submission.status.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(submission.status.color.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(20)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // MARK: - Question Breakdown Section
    
    private var questionBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Answer Breakdown")
                .font(.title2.bold())
                .foregroundColor(AppTheme.primaryText)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(quiz.questions.enumerated()), id: \.element.id) { index, question in
                    if let answer = submission.answers.first(where: { $0.questionID == question.id }) {
                        QuestionAnswerCard(
                            questionNumber: index + 1,
                            question: question,
                            answer: answer,
                            onGrade: { points, feedback in
                                Task {
                                    await viewModel.gradeAnswer(
                                        submissionID: submission.id,
                                        questionID: question.id,
                                        points: points,
                                        feedback: feedback
                                    )
                                }
                            }
                        )
                    }
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

struct ScoreStatItem: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = AppTheme.primaryText
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuestionAnswerCard: View {
    let questionNumber: Int
    let question: Question
    let answer: QuizAnswer
    let onGrade: (Int, String?) -> Void
    
    @State private var isExpanded = false
    @State private var showGradingSheet = false
    @State private var gradingPoints: String = ""
    @State private var gradingFeedback: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                // Question Number with Status
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    if answer.isCorrect == true {
                        Image(systemName: "checkmark")
                            .font(.headline)
                            .foregroundColor(statusColor)
                    } else if answer.isCorrect == false {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(statusColor)
                    } else {
                        Text("\(questionNumber)")
                            .font(.headline)
                            .foregroundColor(statusColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Question \(questionNumber)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.secondaryText)
                    
                    Text(question.text)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.primaryText)
                        .lineLimit(isExpanded ? nil : 2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Points Badge
                VStack(spacing: 2) {
                    Text("\(answer.pointsEarned)/\(question.points)")
                        .font(.headline)
                        .foregroundColor(statusColor)
                    
                    Text("pts")
                        .font(.caption2)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            
            // Expand/Collapse Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(isExpanded ? "Hide Details" : "Show Details")
                        .font(.caption.weight(.medium))
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(AppTheme.primaryBlue)
            }
            
            // Expanded Content
            if isExpanded {
                Divider()
                
                // Answer Content
                VStack(alignment: .leading, spacing: 12) {
                    if question.type == .descriptive {
                        // Descriptive Answer
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Learner's Answer:")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AppTheme.secondaryText)
                            
                            Text(answer.textAnswer ?? "No answer provided")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.primaryText)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.groupedBackground)
                                .cornerRadius(8)
                        }
                        
                        // Manual Grading Button
                        if answer.isCorrect == nil {
                            Button(action: {
                                gradingPoints = "\(answer.pointsEarned)"
                                gradingFeedback = answer.feedback ?? ""
                                showGradingSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "pencil.circle.fill")
                                    Text("Grade This Answer")
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(AppTheme.primaryBlue)
                                .cornerRadius(8)
                            }
                        }
                    } else {
                        // MCQ Answer
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                OptionRow(
                                    option: option,
                                    isSelected: answer.selectedOptionIndices.contains(index),
                                    isCorrect: question.correctAnswerIndices.contains(index),
                                    questionType: question.type
                                )
                            }
                        }
                    }
                    
                    // Explanation
                    if let explanation = question.explanation, !explanation.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                Text("Explanation")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundColor(AppTheme.primaryBlue)
                            
                            Text(explanation)
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.primaryBlue.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Feedback
                    if let feedback = answer.feedback, !feedback.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "message.fill")
                                    .font(.caption)
                                Text("Educator Feedback")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundColor(AppTheme.successGreen)
                            
                            Text(feedback)
                                .font(.caption)
                                .foregroundColor(AppTheme.primaryText)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.successGreen.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(statusColor.opacity(0.3), lineWidth: 2)
        )
        .sheet(isPresented: $showGradingSheet) {
            GradingSheet(
                points: $gradingPoints,
                feedback: $gradingFeedback,
                maxPoints: question.points,
                onSubmit: {
                    if let points = Int(gradingPoints) {
                        onGrade(points, gradingFeedback.isEmpty ? nil : gradingFeedback)
                        showGradingSheet = false
                    }
                }
            )
        }
    }
    
    private var statusColor: Color {
        if let isCorrect = answer.isCorrect {
            return isCorrect ? AppTheme.successGreen : AppTheme.errorRed
        } else {
            return AppTheme.warningOrange
        }
    }
}

struct OptionRow: View {
    let option: String
    let isSelected: Bool
    let isCorrect: Bool
    let questionType: QuestionType
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: iconName)
                .font(.subheadline)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            // Option Text
            Text(option)
                .font(.subheadline)
                .foregroundColor(AppTheme.primaryText)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Status Badge
            if isSelected || isCorrect {
                Image(systemName: statusIcon)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
        }
        .padding(12)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1.5)
        )
    }
    
    private var iconName: String {
        questionType == .singleChoice ? "circle" : "square"
    }
    
    private var iconColor: Color {
        if isSelected && isCorrect {
            return AppTheme.successGreen
        } else if isSelected && !isCorrect {
            return AppTheme.errorRed
        } else if isCorrect {
            return AppTheme.successGreen
        } else {
            return AppTheme.secondaryText
        }
    }
    
    private var statusIcon: String {
        if isSelected && isCorrect {
            return "checkmark.circle.fill"
        } else if isSelected && !isCorrect {
            return "xmark.circle.fill"
        } else if isCorrect {
            return "checkmark.circle"
        } else {
            return ""
        }
    }
    
    private var statusColor: Color {
        if isSelected && isCorrect {
            return AppTheme.successGreen
        } else if isSelected && !isCorrect {
            return AppTheme.errorRed
        } else if isCorrect {
            return AppTheme.successGreen
        } else {
            return AppTheme.secondaryText
        }
    }
    
    private var backgroundColor: Color {
        if isSelected && isCorrect {
            return AppTheme.successGreen.opacity(0.1)
        } else if isSelected && !isCorrect {
            return AppTheme.errorRed.opacity(0.1)
        } else if isCorrect {
            return AppTheme.successGreen.opacity(0.05)
        } else {
            return AppTheme.groupedBackground
        }
    }
    
    private var borderColor: Color {
        if isSelected && isCorrect {
            return AppTheme.successGreen
        } else if isSelected && !isCorrect {
            return AppTheme.errorRed
        } else if isCorrect {
            return AppTheme.successGreen.opacity(0.5)
        } else {
            return Color.clear
        }
    }
}

struct GradingSheet: View {
    @Binding var points: String
    @Binding var feedback: String
    let maxPoints: Int
    let onSubmit: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Points Awarded")) {
                    HStack {
                        TextField("Points", text: $points)
                            .keyboardType(.numberPad)
                        
                        Text("/ \(maxPoints)")
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                
                Section(header: Text("Feedback (Optional)")) {
                    TextEditor(text: $feedback)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Grade Answer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        onSubmit()
                    }
                    .disabled(points.isEmpty || Int(points) == nil || Int(points)! > maxPoints)
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
class LearnerPerformanceViewModel: ObservableObject {
    private let service = QuizResultsService()
    
    func gradeAnswer(submissionID: UUID, questionID: UUID, points: Int, feedback: String?) async {
        let success = await service.gradeDescriptiveAnswer(
            submissionID: submissionID,
            questionID: questionID,
            points: points,
            feedback: feedback
        )
        
        if success {
            // Could show success message or refresh
        }
    }
}
