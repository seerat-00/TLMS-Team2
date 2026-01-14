//
//  AdminCoursesView.swift
//  TLMS-project-main
//
//  Courses tab for Admin Dashboard
//

import SwiftUI

struct AdminCoursesView: View {
    let pendingCourses: [Course]
    let isLoading: Bool
    let onReload: () async -> Void
    
    @State private var courseTabMode = 0 // 0: Pending, 1: Monitor
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Mode", selection: $courseTabMode) {
                    Text("Pending Review").tag(0)
                    Text("Value Monitor").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color(uiColor: .systemGroupedBackground))
                
                // Content
                if courseTabMode == 0 {
                    pendingCoursesList
                } else {
                    AdminCourseValueView()
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Courses")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var pendingCoursesList: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding(40)
                } else if pendingCourses.isEmpty {
                    EmptyStateView(
                        icon: "book.closed.fill",
                        title: "No pending courses",
                        message: "All course submissions have been reviewed"
                    )
                } else {
                    ForEach(pendingCourses) { course in
                        NavigationLink(destination: AdminCourseDetailView(course: course, onStatusChange: {
                            Task {
                                await onReload()
                            }
                        })) {
                            PendingCourseCard(course: course)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
    }
}
