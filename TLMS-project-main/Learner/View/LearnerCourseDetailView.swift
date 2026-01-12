//
//  LearnerCourseDetailView.swift
//  TLMS-project-main
//
//  View for Learners to preview course content and enroll
//

import SwiftUI

struct LearnerCourseDetailView: View {
    let course: Course
    let isEnrolled: Bool
    var onEnroll: () async -> Void
    
    @State private var expandedModules: Set<UUID> = []
    @State private var isEnrolling = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Course")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                            Text(course.category)
                                .font(.subheadline.bold())
                                .foregroundColor(AppTheme.primaryBlue)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if isEnrolled {
                            Label("Enrolled", systemImage: "checkmark.circle.fill")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(AppTheme.successGreen.opacity(0.1))
                                .foregroundColor(AppTheme.successGreen)
                                .cornerRadius(8)
                        }
                    }
                    
                    Divider()
                    
                    Text(course.title)
                        .font(.title2.bold())
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(course.description)
                        .font(.body)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    // Metadata
                    HStack(spacing: 16) {
                        Label("\(course.modules.count) Modules", systemImage: "book.fill")
                        // Add duration or other metadata if available in model
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                }
                .padding()
                .background(AppTheme.secondaryGroupedBackground)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal)
                
                // Content Preview
                VStack(alignment: .leading, spacing: 16) {
                    Text("Course Content")
                        .font(.title3.bold())
                        .foregroundColor(AppTheme.primaryText)
                        .padding(.horizontal)
                    
                    if course.modules.isEmpty {
                        Text("No content available yet.")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryText)
                            .padding(.horizontal)
                    } else {
                        ForEach(Array(course.modules.enumerated()), id: \.element.id) { index, module in
                            ModulePreviewCard(
                                module: module,
                                moduleNumber: index + 1,
                                isExpanded: expandedModules.contains(module.id),
                                onToggle: {
                                    withAnimation {
                                        if expandedModules.contains(module.id) {
                                            expandedModules.remove(module.id)
                                        } else {
                                            expandedModules.insert(module.id)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
                
                Spacer(minLength: 80) // Space for bottom bar
            }
            .padding(.top)
        }
        .background(AppTheme.groupedBackground)
        .navigationTitle("Course Details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !isEnrolled {
                VStack {
                    Divider()
                    HStack {
                        Button(action: {
                            Task {
                                isEnrolling = true
                                await onEnroll()
                                isEnrolling = false
                                // Dismiss to refresh parent view
                                dismiss()
                            }
                        }) {
                            HStack {
                                if isEnrolling {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Enroll Now")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.primaryBlue)
                            .foregroundColor(.white)
                            .cornerRadius(AppTheme.cornerRadius)
                        }
                        .disabled(isEnrolling)
                    }
                    .padding()
                    .background(AppTheme.secondaryGroupedBackground) // Solid background for bar
                }
            }
        }
    }
}
