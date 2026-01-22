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
    @State private var courseToEdit: DashboardCourse? = nil
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
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
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
            NavigationView {
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
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatGlassCard(
                    icon: "book.fill",
                    title: "Courses",
                    value: "\(viewModel.totalCourses)",
                    color: AppTheme.primaryBlue
                )
                
                StatGlassCard(
                    icon: "person.3.fill",
                    title: "Enrollments",
                    value: "\(viewModel.totalEnrollments)",
                    color: AppTheme.successGreen
                )
            }
            
            // Quiz Results Card with Navigation
            NavigationLink(destination: QuizResultsListView(educatorID: user.id)) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.totalQuizSubmissions)")
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("Quiz Submissions")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppTheme.secondaryGroupedBackground)
                .cornerRadius(AppTheme.cornerRadius)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
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
                
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.draftCourses) { course in
                        CourseGlassCard(course: course, onDelete: {
                            viewModel.confirmDelete(course)
                        }, onEdit: {
                            courseToEdit = course
                            showCreateCourse = true
                        }, educatorID: user.id)
                    }
                }
            }
            
            // Other Courses Section
            if !viewModel.otherCourses.isEmpty {
                Text(viewModel.draftCourses.isEmpty ? "Your Courses" : "Published & Under Review")
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.primaryText)
                    .padding(.top, viewModel.draftCourses.isEmpty ? 0 : 8)
                
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.otherCourses) { course in
                        // Show delete button for pending review courses (can be retracted)
                        // Show unpublish button for published courses
                        if course.status == .pendingReview {
                            CourseGlassCard(course: course, onDelete: {
                                viewModel.confirmDelete(course)
                            }, educatorID: user.id)
                        } else if course.status == .published {
                            CourseGlassCard(course: course, onUnpublish: {
                                viewModel.confirmUnpublish(course)
                            }, educatorID: user.id)
                        } else {
                            CourseGlassCard(course: course, educatorID: user.id)
                        }
                    }
                }
            }
            
            // Rejected Courses Section
            if !viewModel.rejectedCourses.isEmpty {
                Text("Rejected Courses")
                    .font(.title2.bold())
                    .foregroundColor(.red)
                    .padding(.top, viewModel.otherCourses.isEmpty && viewModel.draftCourses.isEmpty ? 0 : 8)
                
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.rejectedCourses) { course in
                        CourseGlassCard(
                            course: course,
                            onDelete: {
                                viewModel.confirmDelete(course)
                            },
                            onEdit: {
                                courseToEdit = course
                                showCreateCourse = true
                            },
                            educatorID: user.id
                        )
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

// MARK: - Stat Card

struct StatGlassCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.primaryText)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Course Card

struct CourseGlassCard: View {
    let course: DashboardCourse
    var onDelete: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onUnpublish: (() -> Void)? = nil
    var educatorID: UUID? = nil
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationLink(destination: destinationView) {
            HStack(spacing: 16) {
                // Course Icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.primaryBlue.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.primaryBlue)
                }
                
                // Course Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(course.title)
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // Status Badge
                        HStack(spacing: 4) {
                            Image(systemName: course.status.icon)
                                .font(.caption2)
                            Text(course.status.displayName)
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundColor(course.status.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(course.status.color.opacity(0.1))
                        .cornerRadius(6)
                        
                        // Rating display
                        if let rating = course.ratingAvg, course.ratingCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text(String(format: "%.1f", rating))
                                    .font(.caption2.weight(.medium))
                                Text("(\(course.ratingCount))")
                                    .font(.caption2)
                            }
                            .foregroundColor(AppTheme.secondaryText)
                        }
                        
                        // Learner Count
                        if course.learnerCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .font(.caption2)
                                Text("\(course.learnerCount)")
                                    .font(.caption2)
                            }
                            .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    // Edit button (arrow icon) for drafts
                    if let onEdit = onEdit {
                        Button(action: onEdit) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3)
                                .foregroundColor(AppTheme.primaryBlue)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Unpublish button for published courses
                    if let onUnpublish = onUnpublish {
                        Button(action: onUnpublish) {
                            Image(systemName: "arrow.uturn.down.circle.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Delete button
                    if let onDelete = onDelete {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.red)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Chevron for navigation
                    if onEdit == nil && onDelete == nil && onUnpublish == nil {
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
            }
            .padding(16)
            .background(AppTheme.secondaryGroupedBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var destinationView: some View {
        // Only navigate to reviews for published courses with ratings
        if course.status == .published, let educatorID = educatorID, course.ratingCount > 0 {
            CourseReviewsListView(
                courseID: course.id,
                courseTitle: course.title,
                educatorID: educatorID
            )
        } else {
            EmptyView()
        }
    }
}

// MARK: - Empty Courses Card

struct EmptyCoursesCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 50))
                .foregroundStyle(AppTheme.secondaryText.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No courses yet")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText)
                
                Text("Create your first course to start teaching")
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Approval Banners

struct PendingApprovalBanner: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Account Pending Approval")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Your educator account is awaiting admin approval. You'll be able to create courses once approved.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .shadow(color: .orange.opacity(0.2), radius: 15, y: 5)
    }
}

struct RejectedBanner: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text("Account Rejected")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Your educator account has been rejected. Please contact support for more information.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .shadow(color: .red.opacity(0.2), radius: 15, y: 5)
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
