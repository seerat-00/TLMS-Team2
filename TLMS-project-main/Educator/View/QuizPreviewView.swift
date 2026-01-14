//
//  QuizPreviewView.swift
//  TLMS-project-main
//
//  Step 3: Quiz Preview and Publishing
//

import SwiftUI

struct QuizPreviewView: View {
    @ObservedObject var viewModel: QuizCreationViewModel
    @State private var showSuccessBanner = false
    @State private var successMessage = ""
    @State private var isProcessing = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.groupedBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.newQuiz.title)
                            .font(.largeTitle.bold())
                        
                        if let course = viewModel.selectedCourse {
                            HStack {
                                Image(systemName: "book.fill")
                                    .font(.subheadline)
                                Text(course.title)
                                    .font(.subheadline)
                            }
                            .foregroundColor(AppTheme.secondaryText)
                        }
                        
                        // Quiz Stats
                        HStack(spacing: 20) {
                            HStack(spacing: 6) {
                                Image(systemName: "questionmark.circle.fill")
                                    .foregroundColor(AppTheme.primaryBlue)
                                Text("\(viewModel.newQuiz.questionCount) Questions")
                                    .font(.subheadline)
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(AppTheme.primaryBlue)
                                Text("\(viewModel.newQuiz.totalPoints) Points")
                                    .font(.subheadline)
                            }
                        }
                        .foregroundColor(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Questions Preview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Questions Preview")
                            .font(.title2.bold())
                            .padding(.horizontal)
                        
                        ForEach(Array(viewModel.newQuiz.questions.enumerated()), id: \.element.id) { index, question in
                            QuestionPreviewCard(
                                question: question,
                                questionNumber: index + 1
                            )
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Publish Button
                        Button(action: {
                            handlePublishQuiz()
                        }) {
                            HStack(spacing: 8) {
                                if isProcessing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Publish Quiz")
                                        .font(.headline)
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppTheme.primaryBlue)
                            .foregroundColor(.white)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(isProcessing)
                        
                        // Save as Draft Button
                        Button(action: {
                            handleSaveAsDraft()
                        }) {
                            HStack(spacing: 8) {
                                if isProcessing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Save as Draft")
                                        .font(.headline)
                                    Image(systemName: "doc.badge.plus")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(AppTheme.cornerRadius)
                        }
                        .disabled(isProcessing)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            
            // Success Banner
            if showSuccessBanner {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        Text(successMessage)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    .background(AppTheme.successGreen)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("Preview Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("Saving quiz...")
                        .padding()
                        .background(AppTheme.secondaryGroupedBackground)
                        .cornerRadius(AppTheme.cornerRadius)
                }
            }
        }
    }
    
    private func handleSaveAsDraft() {
        isProcessing = true
        Task {
            await viewModel.saveAsDraft()
            
            if let message = viewModel.saveSuccessMessage {
                successMessage = message
                withAnimation {
                    showSuccessBanner = true
                }
                
                // Wait a moment to show the banner
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                // Dismiss the entire modal back to dashboard
                await MainActor.run {
                    // Find and dismiss the root presentation
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.dismiss(animated: true)
                    }
                }
            }
            isProcessing = false
        }
    }
    
    private func handlePublishQuiz() {
        isProcessing = true
        Task {
            await viewModel.publishQuiz()
            
            if let message = viewModel.saveSuccessMessage {
                successMessage = message
                withAnimation {
                    showSuccessBanner = true
                }
                
                // Wait a moment to show the banner
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                // Dismiss the entire modal back to dashboard
                await MainActor.run {
                    // Find and dismiss the root presentation
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.dismiss(animated: true)
                    }
                }
            }
            isProcessing = false
        }
    }
}

// MARK: - Question Preview Card

struct QuestionPreviewCard: View {
    let question: Question
    let questionNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question Header
            HStack {
                Text("Question \(questionNumber)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Question Type Badge
                HStack(spacing: 4) {
                    Image(systemName: question.type.icon)
                        .font(.caption2)
                    Text(question.type.displayName)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.1))
                .foregroundColor(.purple)
                .cornerRadius(6)
                
                Spacer()
                
                // Points Badge
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text("\(question.points) pt\(question.points == 1 ? "" : "s")")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.primaryBlue.opacity(0.1))
                .foregroundColor(AppTheme.primaryBlue)
                .cornerRadius(6)
            }
            
            // Question Text
            Text(question.text)
                .font(.body)
                .foregroundColor(.primary)
            
            // Type-specific content
            if question.type == .singleChoice {
                // Single Choice Options with Radio Buttons
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(0..<question.options.count, id: \.self) { index in
                        HStack(spacing: 12) {
                            // Radio Button Indicator
                            ZStack {
                                Circle()
                                    .stroke(question.correctAnswerIndices.contains(index) ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                
                                if question.correctAnswerIndices.contains(index) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 12, height: 12)
                                }
                            }
                            
                            // Option Text
                            Text(question.options[index])
                                .font(.subheadline)
                                .foregroundColor(question.correctAnswerIndices.contains(index) ? .primary : .secondary)
                            
                            Spacer()
                            
                            // Correct Answer Label
                            if question.correctAnswerIndices.contains(index) {
                                Text("Correct")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            question.correctAnswerIndices.contains(index) ?
                            Color.green.opacity(0.05) :
                            Color(uiColor: .tertiarySystemGroupedBackground)
                        )
                        .cornerRadius(8)
                    }
                }
            } else if question.type == .multipleChoice {
                // Multiple Choice Options with Checkboxes
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(0..<question.options.count, id: \.self) { index in
                        HStack(spacing: 12) {
                            // Checkbox Indicator
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(question.correctAnswerIndices.contains(index) ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                
                                if question.correctAnswerIndices.contains(index) {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundColor(.green)
                                }
                            }
                            
                            // Option Text
                            Text(question.options[index])
                                .font(.subheadline)
                                .foregroundColor(question.correctAnswerIndices.contains(index) ? .primary : .secondary)
                            
                            Spacer()
                            
                            // Correct Answer Label
                            if question.correctAnswerIndices.contains(index) {
                                Text("Correct")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            question.correctAnswerIndices.contains(index) ?
                            Color.green.opacity(0.05) :
                            Color(uiColor: .tertiarySystemGroupedBackground)
                        )
                        .cornerRadius(8)
                    }
                }
                
                // Show count of correct answers
                Text("\(question.correctAnswerIndices.count) correct answer\(question.correctAnswerIndices.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } else if question.type == .descriptive {
                // Descriptive Question - Show text area placeholder
                VStack(alignment: .leading, spacing: 8) {
                    Text("Student will provide a written answer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                    
                    // Text area placeholder
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Answer area (max \(question.characterLimit) characters)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .frame(height: 120)
                            .overlay(
                                Text("Students will type their answer here...")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.5))
                            )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .cornerRadius(8)
                    
                    // Manual grading notice
                    HStack(spacing: 6) {
                        Image(systemName: "hand.raised.fill")
                            .font(.caption)
                        Text("Requires manual grading by educator")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        QuizPreviewView(viewModel: QuizCreationViewModel(educatorID: UUID()))
    }
}
