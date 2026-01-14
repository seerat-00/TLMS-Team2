//
//  CreateQuizView.swift
//  TLMS-project-main
//
//  Step 1: Basic Quiz Information
//

import SwiftUI

struct CreateQuizView: View {
    @ObservedObject var viewModel: QuizCreationViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Quiz")
                            .font(.largeTitle.bold())
                        
                        Text("Create an assessment to evaluate learner knowledge")
                            .font(.body)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        // Quiz Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quiz Title")
                                .font(.headline)
                                .foregroundColor(AppTheme.secondaryText)
                            
                            TextField("e.g. Module 1 Assessment", text: $viewModel.newQuiz.title)
                                .font(.body)
                                .padding()
                                .background(AppTheme.secondaryGroupedBackground)
                                .cornerRadius(AppTheme.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                                )
                            
                            Text("Required - Give your quiz a descriptive title")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                                .padding(.top, 4)
                        }
                        
                        // Course Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select Course")
                                .font(.headline)
                                .foregroundColor(AppTheme.secondaryText)
                            
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .padding()
                                    Text("Loading courses...")
                                        .foregroundColor(AppTheme.secondaryText)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.secondaryGroupedBackground)
                                .cornerRadius(AppTheme.cornerRadius)
                            } else if viewModel.availableCourses.isEmpty {
                                VStack(spacing: 8) {
                                    Text("No courses available")
                                        .foregroundColor(AppTheme.secondaryText)
                                    Text("Create a course first before adding quizzes")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.secondaryGroupedBackground)
                                .cornerRadius(AppTheme.cornerRadius)
                            } else {
                                Menu {
                                    ForEach(viewModel.availableCourses) { course in
                                        Button(action: {
                                            viewModel.selectCourse(course)
                                        }) {
                                            Text(course.title)
                                            if viewModel.selectedCourse?.id == course.id {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(viewModel.selectedCourse?.title ?? "Select a course")
                                            .foregroundColor(viewModel.selectedCourse == nil ? AppTheme.secondaryText : AppTheme.primaryText)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                    .padding()
                                    .background(AppTheme.secondaryGroupedBackground)
                                    .cornerRadius(AppTheme.cornerRadius)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                                    )
                                }
                            }
                            
                            Text("Quiz will be linked to this course")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                                .padding(.top, 4)
                        }
                    }
                    .padding(24)
                    .background(AppTheme.secondaryGroupedBackground)
                    .cornerRadius(AppTheme.cornerRadius)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                    
                    // Next Button
                    NavigationLink(destination: QuizQuestionsView(viewModel: viewModel)) {
                        HStack(spacing: 8) {
                            Text("Next")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.isQuizValid && viewModel.selectedCourse != nil ? AppTheme.primaryBlue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                    .disabled(!viewModel.isQuizValid || viewModel.selectedCourse == nil)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Create Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("Back")
                            .font(.body)
                    }
                    .foregroundColor(AppTheme.primaryBlue)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CreateQuizView(viewModel: QuizCreationViewModel(educatorID: UUID()))
    }
}
