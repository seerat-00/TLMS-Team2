//
//  LessonQuizEditorView.swift
//  TLMS-project-main
//
//  Quiz editor for lessons within course structure
//

import SwiftUI

struct LessonQuizEditorView: View {
    @ObservedObject var viewModel: CourseCreationViewModel
    let moduleID: UUID
    let lessonID: UUID
    let lessonTitle: String
    
    @State private var questions: [Question] = []
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.groupedBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(lessonTitle)
                            .font(.largeTitle.bold())
                        
                        Text("Add questions to assess learner knowledge")
                            .font(.body)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Questions List
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Questions")
                                .font(.title2.bold())
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.addQuestionToLesson(moduleID: moduleID, lessonID: lessonID)
                                loadQuestions()
                            }) {
                                Label("Add Question", systemImage: "plus")
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.primaryBlue.opacity(0.1))
                                    .foregroundColor(AppTheme.primaryBlue)
                                    .cornerRadius(AppTheme.cornerRadius)
                            }
                        }
                        .padding(.horizontal)
                        
                        if questions.isEmpty {
                            EmptyStateView(
                                icon: "questionmark.circle",
                                title: "No Questions Yet",
                                message: "Add questions to create your quiz."
                            )
                        } else {
                            ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                                LessonQuestionCard(
                                    question: question,
                                    questionNumber: index + 1,
                                    moduleID: moduleID,
                                    lessonID: lessonID,
                                    viewModel: viewModel,
                                    onDelete: {
                                        viewModel.deleteQuestionFromLesson(moduleID: moduleID, lessonID: lessonID, questionIndex: index)
                                        loadQuestions()
                                    },
                                    onUpdate: {
                                        loadQuestions()
                                    }
                                )
                            }
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Save Button
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Text("Done")
                                .font(.headline)
                            Image(systemName: "checkmark")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            canSaveQuiz ?
                            AppTheme.primaryBlue :
                            Color.gray.opacity(0.3)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.cornerRadius)
                        .shadow(color: canSaveQuiz ? AppTheme.primaryBlue.opacity(0.3) : .clear, radius: 8, y: 4)
                    }
                    .disabled(!canSaveQuiz)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(lessonTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadQuestions()
        }
    }
    
    private func loadQuestions() {
        questions = viewModel.getQuizQuestions(moduleID: moduleID, lessonID: lessonID)
    }
    
    private var canSaveQuiz: Bool {
        !questions.isEmpty && questions.allSatisfy { $0.isValid }
    }
}

// MARK: - Lesson Question Card

struct LessonQuestionCard: View {
    @State var question: Question
    let questionNumber: Int
    let moduleID: UUID
    let lessonID: UUID
    @ObservedObject var viewModel: CourseCreationViewModel
    let onDelete: () -> Void
    let onUpdate: () -> Void
    
    @State private var isExpanded = true
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Question Header
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    // Expand/Collapse Button
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
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
                        
                        // Manual Grading Badge for Descriptive
                        if question.type == .descriptive {
                            HStack(spacing: 4) {
                                Image(systemName: "hand.raised.fill")
                                    .font(.caption2)
                                Text("Manual Grading Required")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
                        }
                        
                        if !isExpanded && !question.text.isEmpty {
                            Text(question.text)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    // Delete Button
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                }
            }
            .padding()
            
            // Question Details (Expandable)
            if isExpanded {
                Divider()
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    // Question Type Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question Type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Menu {
                            ForEach(QuestionType.allCases) { type in
                                Button(action: {
                                    question.type = type
                                    // Reset fields based on type
                                    if type == .descriptive {
                                        question.options = []
                                        question.correctAnswerIndices = []
                                        question.requiresManualGrading = true
                                    } else {
                                        if question.options.isEmpty {
                                            question.options = ["", "", "", ""]
                                        }
                                        if question.correctAnswerIndices.isEmpty {
                                            question.correctAnswerIndices = [0]
                                        }
                                        question.requiresManualGrading = false
                                    }
                                    updateQuestion()
                                }) {
                                    HStack {
                                        Image(systemName: type.icon)
                                        VStack(alignment: .leading) {
                                            Text(type.displayName)
                                            Text(type.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        if question.type == type {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: question.type.icon)
                                Text(question.type.displayName)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Question Text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question Text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .topLeading) {
                            if question.text.isEmpty {
                                Text("Enter your question here...")
                                    .foregroundColor(.gray.opacity(0.6))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            
                            TextEditor(text: $question.text)
                                .frame(minHeight: 80)
                                .scrollContentBackground(.hidden)
                                .padding(4)
                                .onChange(of: question.text) { _, _ in
                                    updateQuestion()
                                }
                        }
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                    
                    // Type-specific content
                    if question.type == .singleChoice || question.type == .multipleChoice {
                        // Options for MCQ
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Answer Options")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(0..<4) { index in
                                HStack(spacing: 12) {
                                    // Selection Button (Radio for single, Checkbox for multiple)
                                    Button(action: {
                                        if question.type == .singleChoice {
                                            question.correctAnswerIndices = [index]
                                        } else {
                                            if question.correctAnswerIndices.contains(index) {
                                                question.correctAnswerIndices.removeAll { $0 == index }
                                            } else {
                                                question.correctAnswerIndices.append(index)
                                            }
                                        }
                                        updateQuestion()
                                    }) {
                                        if question.type == .singleChoice {
                                            Image(systemName: question.correctAnswerIndices.contains(index) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(question.correctAnswerIndices.contains(index) ? .green : .gray)
                                                .font(.title3)
                                        } else {
                                            Image(systemName: question.correctAnswerIndices.contains(index) ? "checkmark.square.fill" : "square")
                                                .foregroundColor(question.correctAnswerIndices.contains(index) ? .green : .gray)
                                                .font(.title3)
                                        }
                                    }
                                    
                                    // Option Text
                                    TextField("Option \(index + 1)", text: Binding(
                                        get: { 
                                            index < question.options.count ? question.options[index] : ""
                                        },
                                        set: { newValue in
                                            if index < question.options.count {
                                                question.options[index] = newValue
                                            } else {
                                                while question.options.count <= index {
                                                    question.options.append("")
                                                }
                                                question.options[index] = newValue
                                            }
                                            updateQuestion()
                                        }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                            
                            if question.type == .singleChoice {
                                Text("Select the correct answer")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Select all correct answers (\(question.correctAnswerIndices.count) selected)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else if question.type == .descriptive {
                        // Character limit info for descriptive
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "text.alignleft")
                                    .foregroundColor(.secondary)
                                Text("Character Limit: \(question.characterLimit) characters")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                            .cornerRadius(8)
                            
                            Text("Based on \(question.points) point\(question.points == 1 ? "" : "s") × 100 characters")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Points
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Stepper(value: Binding(
                                get: { question.points },
                                set: { newValue in
                                    question.points = max(1, newValue)
                                    updateQuestion()
                                }
                            ), in: 1...10) {
                                Text("\(question.points) point\(question.points == 1 ? "" : "s")")
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        .alert("Delete Question", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete this question?")
        }
    }
    
    private func updateQuestion() {
        viewModel.updateQuestionInLesson(moduleID: moduleID, lessonID: lessonID, question: question)
        onUpdate()
    }
}

#Preview {
    NavigationView {
        LessonQuizEditorView(
            viewModel: CourseCreationViewModel(educatorID: UUID()),
            moduleID: UUID(),
            lessonID: UUID(),
            lessonTitle: "Python Basics Quiz"
        )
    }
}
