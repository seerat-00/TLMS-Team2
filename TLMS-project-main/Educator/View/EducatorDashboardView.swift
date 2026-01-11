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
    @State private var showProfile = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
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
                            
                            // Primary CTA
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
                    Menu {
                        Button(action: { showProfile = true }) {
                            Label("Profile", systemImage: "person.circle")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            Task {
                                await viewModel.loadData(educatorID: user.id)
                            }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: handleLogout) {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .id(user.id)
        .task {
            await viewModel.loadData(educatorID: user.id)
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
    }
    
    // MARK: - Courses Section
    
    private var coursesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Courses")
                .font(.title2.bold())
                .foregroundColor(AppTheme.primaryText)
            
            if viewModel.recentCourses.isEmpty {
                EmptyCoursesCard()
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.recentCourses) { course in
                        CourseGlassCard(course: course)
                    }
                }
            }
        }
    }
    
    // MARK: - Create Course Button
    
    private var createCourseButton: some View {
        NavigationLink(destination: CreateCourseView(viewModel: CourseCreationViewModel(educatorID: user.id))) {
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
    
    private func handleLogout() {
        Task {
            await authService.signOut()
        }
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
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
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
            
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(16)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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
