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
                            .font(.system(size: 28, weight: .bold))
                        
                        Text("Start by providing the basic details for your course.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Form Fields in Glass Container
                    VStack(spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Course Title")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            TextField("e.g. Mastering SwiftUI", text: $viewModel.newCourse.title)
                                .font(.system(size: 18))
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
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
                                        .foregroundColor(viewModel.newCourse.category.isEmpty ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                            
                            Text("Helps learners discover your course easily")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ZStack(alignment: .topLeading) {
                                if viewModel.newCourse.description.isEmpty {
                                    Text("Describe what learners will learn in this course...")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                }
                                
                                TextEditor(text: $viewModel.newCourse.description)
                                    .frame(minHeight: 120)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial) // Glass Effect
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    // Continue Button
                    NavigationLink(destination: CourseStructureView(viewModel: viewModel)) {
                        HStack(spacing: 8) {
                            Text("Next")
                                .font(.system(size: 18, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                            .background(
                                viewModel.isCourseInfoValid ?
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: viewModel.isCourseInfoValid ? .purple.opacity(0.3) : .clear, radius: 10, y: 5)
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
