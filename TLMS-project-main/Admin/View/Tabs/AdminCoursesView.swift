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
    @StateObject private var courseValueViewModel = AdminCourseValueViewModel()
    @State private var hasLoadedCourses = false
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
                
                // Content - Use ZStack with opacity to prevent view recreation
                ZStack {
                    pendingCoursesList
                        .opacity(courseTabMode == 0 ? 1 : 0)
                        .zIndex(courseTabMode == 0 ? 1 : 0)
                    
                    AdminCourseValueView(viewModel: courseValueViewModel)
                        .opacity(courseTabMode == 1 ? 1 : 0)
                        .zIndex(courseTabMode == 1 ? 1 : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Courses")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Load courses only once on initial appearance
                if courseTabMode == 1 && !hasLoadedCourses && courseValueViewModel.courses.isEmpty {
                    hasLoadedCourses = true
                    Task {
                        await courseValueViewModel.loadCourses()
                    }
                }
            }
            .onChange(of: courseTabMode) { oldValue, newValue in
                // Load courses when switching to Value Monitor tab for the first time
                if newValue == 1 && !hasLoadedCourses && courseValueViewModel.courses.isEmpty {
                    hasLoadedCourses = true
                    Task {
                        await courseValueViewModel.loadCourses()
                    }
                }
            }
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
        .frame(maxHeight: .infinity)
    }
}
