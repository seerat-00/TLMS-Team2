//
//  LearnerDashboardView.swift
//  TLMS-project-main
//
//  Dashboard for learner users
//

import SwiftUI

struct LearnerDashboardView: View {
    let user: User
    @EnvironmentObject var authService: AuthService
    @StateObject private var courseService = CourseService()
    @State private var publishedCourses: [Course] = []
    @State private var isLoading = false
    @State private var showProfile = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Welcome header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome back,")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text(user.fullName)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Quick stats
                        HStack(spacing: 16) {
                            StatCard(
                                icon: "book.fill",
                                title: "Courses",
                                value: "\(publishedCourses.count)",
                                color: AppTheme.primaryBlue
                            )
                            
                            StatCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Progress",
                                value: "0%",
                                color: AppTheme.successGreen
                            )
                        }
                        .padding(.horizontal)
                        
                        // Course sections
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Available Courses")
                                .font(.title2.bold())
                                .foregroundColor(AppTheme.primaryText)
                                .padding(.horizontal)
                            
                            if isLoading {
                                ProgressView()
                                    .padding()
                            } else if publishedCourses.isEmpty {
                                EmptyStateView(
                                    icon: "book.closed.fill",
                                    title: "No courses available",
                                    message: "Check back later for new content"
                                )
                                .padding(.horizontal)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(publishedCourses) { course in
                                        PublishedCourseCard(course: course)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showProfile = true }) {
                            Label("Profile", systemImage: "person.circle")
                        }
                        
                        Button(action: {
                            Task {
                                await loadData()
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
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoading = true
        publishedCourses = await courseService.fetchPublishedCourses()
        isLoading = false
    }
    
    private func handleLogout() {
        Task {
            await authService.signOut()
        }
    }
}

// MARK: - Published Course Card

struct PublishedCourseCard: View {
    let course: Course
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
                    .lineLimit(2)
                
                Text(course.description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 10))
                        Text(course.category)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(AppTheme.primaryBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.primaryBlue.opacity(0.1))
                    .cornerRadius(6)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 10))
                        Text("\(course.modules.count) Modules")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(AppTheme.secondaryText)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(16)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
// MARK: - Stat Card Component

struct StatCard: View {
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

// MARK: - Empty State Component

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(AppTheme.secondaryText.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    LearnerDashboardView(user: User(
        id: UUID(),
        email: "learner@example.com",
        fullName: "John Doe",
        role: .learner,
        approvalStatus: .approved,
        resumeUrl: nil,
        passwordResetRequired: false,
        createdAt: Date(),
        updatedAt: Date()
    ))
    .environmentObject(AuthService())
}

