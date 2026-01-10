//
//  CreateCourseView.swift
//  TLMS-project-main
//
//  Step 1: Basic Course Information
//

import SwiftUI

struct CreateCourseView: View {
    @ObservedObject var viewModel: CourseCreationViewModel
    @Environment(\.dismiss) var dismiss
    
    // Categories for the dropdown
    let categories = ["Development", "Business", "Design", "Marketing", "Lifestyle", "Photography", "Health & Fitness", "Music", "Teaching & Academics"]
    
    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Course")
                            .font(.largeTitle.bold())
                        
                        Text("Start by providing the basic details for your course.")
                            .font(.body)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Course Title")
                                .font(.headline)
                                .foregroundColor(AppTheme.secondaryText)
                            
                            TextField("e.g. Mastering SwiftUI", text: $viewModel.newCourse.title)
                                .font(.body)
                                .padding()
                                .background(AppTheme.secondaryGroupedBackground)
                                .cornerRadius(AppTheme.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                                )
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(AppTheme.secondaryText)
                            
                            Menu {
                                ForEach(categories, id: \.self) { category in
                                    Button(action: {
                                        viewModel.newCourse.category = category
                                    }) {
                                        Text(category)
                                        if viewModel.newCourse.category == category {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.newCourse.category.isEmpty ? "Select Category" : viewModel.newCourse.category)
                                        .foregroundColor(viewModel.newCourse.category.isEmpty ? AppTheme.secondaryText : AppTheme.primaryText)
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
                            
                            Text("Helps learners discover your course easily")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                                .padding(.top, 4)
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(AppTheme.secondaryText)
                            
                            ZStack(alignment: .topLeading) {
                                if viewModel.newCourse.description.isEmpty {
                                    Text("Describe what learners will learn in this course...")
                                        .foregroundColor(AppTheme.secondaryText.opacity(0.6))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                }
                                
                                TextEditor(text: $viewModel.newCourse.description)
                                    .frame(minHeight: 120)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                            }
                            .background(AppTheme.secondaryGroupedBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                            )
                        }
                    }
                    .padding(24)
                    .background(AppTheme.secondaryGroupedBackground)
                    .cornerRadius(AppTheme.cornerRadius)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                    
                    // Continue Button
                    NavigationLink(destination: CourseStructureView(viewModel: viewModel)) {
                        HStack(spacing: 8) {
                            Text("Next")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.isCourseInfoValid ? AppTheme.primaryBlue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                    .disabled(!viewModel.isCourseInfoValid)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Create Course")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        CreateCourseView(viewModel: CourseCreationViewModel(educatorID: UUID()))
    }
}
