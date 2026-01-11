//
//  AdminCourseDetailView.swift
//  TLMS-project-main
//
//  View for Admin to review and approve/reject courses
//

import SwiftUI

struct AdminCourseDetailView: View {
    let course: Course
    @Environment(\.dismiss) var dismiss
    @StateObject private var courseService = CourseService()
    @State private var isProcessing = false
    @State private var expandedModules: Set<UUID> = []
    
    var onStatusChange: (() -> Void)?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with Educator Info
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Submitted by Educator")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            // Ideally fetch educator name here or pass it in
                            Text("Educator ID: \(course.educatorID)")
                                .font(.system(size: 16, weight: .medium))
                        }
                        Spacer()
                        
                        Text(course.status.displayName)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(course.status.color.opacity(0.1))
                            .foregroundColor(course.status.color)
                            .cornerRadius(8)
                    }
                    
                    Divider()
                    
                    Text(course.title)
                        .font(.title2.bold())
                    
                    Text(course.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label(course.category, systemImage: "folder.fill")
                        Spacer()
                        Label("\(course.modules.count) Modules", systemImage: "book.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Content Preview
                VStack(alignment: .leading, spacing: 16) {
                    Text("Course Content")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(Array(course.modules.enumerated()), id: \.element.id) { index, module in
                        ModulePreviewCard(
                            module: module,
                            moduleNumber: index + 1,
                            isExpanded: expandedModules.contains(module.id),
                            onToggle: {
                                if expandedModules.contains(module.id) {
                                    expandedModules.remove(module.id)
                                } else {
                                    expandedModules.insert(module.id)
                                }
                            }
                        )
                    }
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button(action: rejectCourse) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                            } else {
                                Text("Reject")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                    .disabled(isProcessing)
                    
                    Button(action: approveCourse) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                            } else {
                                Text("Approve")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                    .disabled(isProcessing)
                }
                .padding()
                .padding(.bottom, 20)
            }
            .padding(.top)
        }
        .background(AppTheme.groupedBackground)
        .navigationTitle("Review Course")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Actions
    
    private func approveCourse() {
        Task {
            isProcessing = true
            let success = await courseService.updateCourseStatus(courseID: course.id, status: .published)
            isProcessing = false
            if success {
                onStatusChange?()
                dismiss()
            }
        }
    }
    
    private func rejectCourse() {
        Task {
            isProcessing = true
            let success = await courseService.updateCourseStatus(courseID: course.id, status: .rejected)
            isProcessing = false
            if success {
                onStatusChange?()
                dismiss()
            }
        }
    }
}
