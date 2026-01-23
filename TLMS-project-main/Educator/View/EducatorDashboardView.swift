//
//  EducatorDashboardView.swift
//  TLMS-project-main
//
//  High-fidelity Educator Landing Screen
//

import SwiftUI

struct EducatorDashboardView: View {
    let user: User
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = EducatorDashboardViewModel()
    @State private var showCreateCourse = false
    @State private var courseToEdit: Course? = nil
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            dashboardView
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }
                .tag(0)
            
            // Profile Tab
            EducatorProfileView(user: user)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(1)
        }
        .tint(AppTheme.primaryBlue)
        .id(user.id)
        .task {
            await viewModel.loadData(educatorID: user.id)
        }
        .fullScreenCover(isPresented: $showCreateCourse, onDismiss: {
            // Refresh dashboard when course creation is dismissed
            courseToEdit = nil
            Task {
                await viewModel.loadData(educatorID: user.id)
            }
        }) {
            NavigationStack {
                if let courseToEdit = courseToEdit {
                    // Editing existing draft course
                    CreateCourseView(viewModel: CourseCreationViewModel(educatorID: user.id, existingCourse: courseToEdit))
                } else {
                    // Creating new course
                    CreateCourseView(viewModel: CourseCreationViewModel(educatorID: user.id))
                }
            }
        }
    }
    
    // MARK: - Dashboard View
    
    @ViewBuilder
    private var dashboardView: some View {
        NavigationStack {
            ZStack {
                // Professional background
                AppTheme.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Approval status check
                        if user.approvalStatus == .pending {
                            PendingApprovalBanner()
                                .padding(.horizontal)
                                .padding(.top)
                        } else if user.approvalStatus == .rejected {
                            RejectedBanner()
                                .padding(.horizontal)
                                .padding(.top)
                        } else {
                            // Header Section
                            headerSection
                                .padding(.top, 8)
                            
                            // Stats Overview
                            statsSection
                            
                            // Ongoing Courses
                            coursesSection
                            
                            // Primary CTAs
                            createCourseButton
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Educator Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.loadData(educatorID: user.id)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Profile Photo Placeholder
            ZStack {
                Circle()
                    .fill(AppTheme.primaryBlue.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text(user.fullName.prefix(1).uppercased())
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.primaryBlue)
            }
            
            // Welcome Text
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                
                Text(user.fullName)
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.primaryText)
                
                // Educator Badge
                HStack(spacing: 4) {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .font(.caption)
                    Text("Educator")
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(AppTheme.primaryBlue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.primaryBlue.opacity(0.1))
                .cornerRadius(6)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "book.fill",
                title: "Courses",
                value: "\(viewModel.totalCourses)",
                color: AppTheme.primaryBlue
            )
            
            StatCard(
                icon: "person.3.fill",
                title: "Enrollments",
                value: "\(viewModel.totalEnrollments)",
                color: AppTheme.successGreen
            )
        }
    }
    
    // MARK: - Courses Section
    
    private var coursesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Draft Courses Section
            if !viewModel.draftCourses.isEmpty {
                Text("Drafts")
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.primaryText)
                
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.draftCourses) { course in
                        NavigationLink(destination: EducatorCoursePreviewView(courseId: course.id, draftCourse: course)) {
                            EducatorCourseCard(
                                course: course,
                                onDelete: { viewModel.confirmDelete(course) },
                                onEdit: {
                                    courseToEdit = course
                                    showCreateCourse = true
                                },
                                showPreviewIcon: true
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Other Courses Section
            if !viewModel.otherCourses.isEmpty {
                Text(viewModel.draftCourses.isEmpty ? "Your Courses" : "Published & Under Review")
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.primaryText)
                    .padding(.top, viewModel.draftCourses.isEmpty ? 0 : 8)
                
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.otherCourses) { course in
                        if course.status == .pendingReview || course.status == .rejected {
                            // Wrap Pending and Rejected courses in NavigationLink for preview
                            NavigationLink(destination: EducatorCoursePreviewView(courseId: course.id)) {
                                EducatorCourseCard(
                                    course: course,
                                    onDelete: { viewModel.confirmDelete(course) },
                                    showPreviewIcon: true
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else if course.status == .published {
                            // Published courses
                            NavigationLink(destination: EducatorCoursePreviewView(courseId: course.id)) {
                                EducatorCourseCard(
                                    course: course,
                                    onUnpublish: { viewModel.confirmUnpublish(course) },
                                    showPreviewIcon: true
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            EducatorCourseCard(course: course)
                        }
                    }
                }
            }
            
            // Empty state
            if viewModel.recentCourses.isEmpty {
                EmptyCoursesCard()
            }
        }
        .alert(viewModel.courseToDelete?.status == .pendingReview ? "Retract Course" : "Delete Course", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.courseToDelete = nil
            }
            Button(viewModel.courseToDelete?.status == .pendingReview ? "Retract" : "Delete", role: .destructive) {
                if let course = viewModel.courseToDelete {
                    Task {
                        _ = await viewModel.deleteCourse(course)
                        viewModel.courseToDelete = nil
                    }
                }
            }
        } message: {
            if let course = viewModel.courseToDelete {
                if course.status == .pendingReview {
                    Text("Are you sure you want to retract '\(course.title)' from review? This will permanently delete the course.")
                } else {
                    Text("Are you sure you want to delete '\(course.title)'? This action cannot be undone.")
                }
            }
        }
        .alert("Unpublish Course", isPresented: $viewModel.showUnpublishConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.courseToUnpublish = nil
            }
            Button("Unpublish", role: .destructive) {
                if let course = viewModel.courseToUnpublish {
                    Task {
                        _ = await viewModel.unpublishCourse(course)
                        viewModel.courseToUnpublish = nil
                    }
                }
            }
        } message: {
            if let course = viewModel.courseToUnpublish {
                Text("Are you sure you want to unpublish '\(course.title)'? This will move the course back to drafts and make it unavailable to learners.")
            }
        }
    }
    
    // MARK: - Create Course Button
    
    private var createCourseButton: some View {
        Button(action: {
            showCreateCourse = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                
                Text("Create New Course")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.primaryBlue)
            .foregroundColor(.white)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 8)
    }
    
}

#Preview {
    EducatorDashboardView(user: User(
        id: UUID(),
        email: "educator@example.com",
        fullName: "Jane Smith",
        role: .educator,
        approvalStatus: .approved,
        resumeUrl: nil,
        passwordResetRequired: false,
        createdAt: Date(),
        updatedAt: Date()
    ))
    .environmentObject(AuthService())
}
