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
    @State private var enrolledCourses: [Course] = []
    @State private var isLoading = false
    @State private var selectedTab = 0 // 0: Browse, 1: My Courses
    @State private var selectedSortOption: CourseSortOption = .relevance
    
    @State private var showProfile = false
    @State private var showingError = false
    @Environment(\.colorScheme) var colorScheme
    
    // Computed property for sorted courses
    private var sortedCourses: [Course] {
        let coursesToSort = selectedTab == 0 ? publishedCourses : enrolledCourses
        
        switch selectedSortOption {
        case .relevance:
            // Sort by newest first (as a proxy for relevance)
            return coursesToSort.sorted { $0.createdAt > $1.createdAt }
        case .popularity:
            // Sort by enrollment count (descending)
            return coursesToSort.sorted { $0.enrollmentCount > $1.enrollmentCount }
        case .newest:
            // Sort by creation date (descending)
            return coursesToSort.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background
                AppTheme.groupedBackground
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

                        // Quick stats (Reduced to just Course Count for now, or just remove Progress)
                        HStack(spacing: 16) {
                            StatCard(
                                icon: "book.fill",
                                title: "Enrolled",
                                value: "\(enrolledCourses.count)",
                                color: AppTheme.primaryBlue
                            )
                            
                            StatCard(
                                icon: "checkmark.seal.fill",
                                title: "Completed",
                                value: "0",
                                color: AppTheme.successGreen
                            )
                        }
                        .padding(.horizontal)
                        
                        // Tab Selection
                        Picker("View Mode", selection: $selectedTab) {
                            Text("Browse Courses").tag(0)
                            Text("My Courses").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Sort Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sort by")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(AppTheme.secondaryText)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(CourseSortOption.allCases) { option in
                                        SortOptionButton(
                                            option: option,
                                            isSelected: selectedSortOption == option,
                                            action: {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    selectedSortOption = option
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)
                        
                        // Course List
                        VStack(alignment: .leading, spacing: 16) {
                            Text(selectedTab == 0 ? "Available Courses" : "My Learning")
                                .font(.title2.bold())
                                .foregroundColor(AppTheme.primaryText)
                                .padding(.horizontal)
                            
                            if isLoading {
                                ProgressView()
                                    .padding()
                            } else {
                                if sortedCourses.isEmpty {
                                    EmptyStateView(
                                        icon: "book.closed.fill",
                                        title: selectedTab == 0 ? "No courses available" : "No enrollments yet",
                                        message: selectedTab == 0 ? "Check back later for new content" : "Browse available courses to start learning"
                                    )
                                    .padding(.horizontal)
                                } else {
                                    LazyVStack(spacing: 16) {
                                        ForEach(sortedCourses) { course in
                                            NavigationLink(destination: 
                                                LearnerCourseDetailView(
                                                    course: course,
                                                    isEnrolled: isEnrolled(course),
                                                    onEnroll: {
                                                        await enroll(course: course)
                                                    }
                                                )
                                            ) {
                                                PublishedCourseCard(
                                                    course: course,
                                                    isEnrolled: isEnrolled(course),
                                                    onEnroll: {
                                                        await enroll(course: course)
                                                    }
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
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
                        Button {
                            showProfile = true
                        } label: {
                            Label("Profile", systemImage: "person.circle")
                        }
                        
                        Divider()
                        
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
            .alert("Enrollment Failed", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(courseService.errorMessage ?? "An unknown error occurred")
            }
        }
        .id(user.id)
        .task {
            await loadData()
        }
    }
    
    private func isEnrolled(_ course: Course) -> Bool {
        enrolledCourses.contains(where: { $0.id == course.id })
    }
    
    private func enroll(course: Course) async {
        let success = await courseService.enrollInCourse(courseID: course.id, userID: user.id)
        if success {
            await loadData()
            selectedTab = 1 // Switch to enrolled tab
        } else {
            showingError = true
        }
    }
    
    private func loadData() async {
        isLoading = true
        async let published = courseService.fetchPublishedCourses()
        async let enrolled = courseService.fetchEnrolledCourses(userID: user.id)
        
        let (pub, enr) = await (published, enrolled)
        
        self.publishedCourses = pub
        self.enrolledCourses = enr
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
    let isEnrolled: Bool
    var onEnroll: () async -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isEnrolling = false

    // Fallbacks for category styling if Course doesn't provide color/icon
    private var categoryColor: Color {
        switch course.category.lowercased() {
        case "design": return .purple
        case "development", "programming", "code": return .blue
        case "marketing": return .orange
        case "business": return .teal
        case "data", "analytics": return .green
        case "photography": return .pink
        case "music": return .indigo
        default: return .gray
        }
    }

    private var categoryIcon: String {
        switch course.category.lowercased() {
        case "design": return "pencil.and.outline"
        case "development", "programming", "code": return "chevron.left.forwardslash.chevron.right"
        case "marketing": return "megaphone.fill"
        case "business": return "briefcase.fill"
        case "data", "analytics": return "chart.bar.fill"
        case "photography": return "camera.fill"
        case "music": return "music.note"
        default: return "book.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Course Icon
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 24))
                    .foregroundColor(categoryColor)
            }
            
            // Course Info
            VStack(alignment: .leading, spacing: 6) {
                Text(course.title)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(course.description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 10))
                        Text(course.category)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(categoryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.15))
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
            
            // Action Button
            if isEnrolled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.successGreen)
            } else {
                Button(action: {
                    Task {
                        isEnrolling = true
                        await onEnroll()
                        isEnrolling = false
                    }
                }) {
                    if isEnrolling {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Enroll")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.primaryBlue)
                            .cornerRadius(20)
                    }
                }
                .disabled(isEnrolling)
            }
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
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.secondaryGroupedBackground)
                .shadow(
                    color: color.opacity(colorScheme == .dark ? 0.3 : 0.15),
                    radius: 15,
                    y: 5
                )
        )
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

// MARK: - Sort Option Button Component

struct SortOptionButton: View {
    let option: CourseSortOption
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: option.icon)
                    .font(.system(size: 14, weight: .semibold))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.displayName)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text(option.description)
                        .font(.system(size: 11))
                        .opacity(0.8)
                }
            }
            .foregroundColor(isSelected ? .white : AppTheme.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.primaryBlue : AppTheme.secondaryGroupedBackground)
                    .shadow(
                        color: isSelected ? AppTheme.primaryBlue.opacity(0.3) : Color.black.opacity(0.05),
                        radius: isSelected ? 8 : 2,
                        x: 0,
                        y: isSelected ? 4 : 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? AppTheme.primaryBlue : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
        }
        .buttonStyle(.plain)
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
