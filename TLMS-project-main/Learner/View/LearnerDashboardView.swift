//
//  LearnerDashboardView.swift
//  TLMS-project-main
//
//  Dashboard for learner users
//

import SwiftUI
import Supabase

struct LearnerDashboardView: View {
    let user: User
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = LearnerDashboardViewModel()
    @State private var selectedTab = 0
    @State private var dashboardRefreshTrigger = UUID()
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Browse Courses Tab
            courseListView(courses: viewModel.publishedCourses.filter { course in
                !viewModel.isEnrolled(course)
            }, title: "Browse Courses", showSearch: false)
            .id(dashboardRefreshTrigger)
            .tabItem {
                Label("Browse", systemImage: "book.fill")
            }
            .tag(0)
            
            // My Courses Tab
            courseListView(
                courses: viewModel.enrolledCourses,
                title: "My Courses",
                showSearch: false
            )
            .id(dashboardRefreshTrigger)
            .tabItem {
                Label("My Courses", systemImage: "person.fill")
            }
            .tag(1)
            
            // Search Tab
            searchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(2)
            
            // Profile Tab
            ProfileView(user: user)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(AppTheme.primaryBlue)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .task {
            await viewModel.loadData(userId: user.id)
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .courseProgressUpdated)
        ) { _ in
            dashboardRefreshTrigger = UUID()   // 🔥 THIS LINE WAS MISSING
            Task {
                await viewModel.loadData(userId: user.id)
            }
        }        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Failed to enroll in course")
        }
    }
    
    // MARK: - Search View
    
    @ViewBuilder
    private func searchView() -> some View {
        NavigationStack {
            ZStack {
                AppTheme.groupedBackground
                    .ignoresSafeArea(edges: .top)
                
                VStack(spacing: 0) {
                    // Category Grid (Apple TV style)
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(CourseCategories.all, id: \.self) { category in
                                NavigationLink(destination: CategoryCoursesView(
                                    category: category,
                                    courses: viewModel.publishedCourses.filter { $0.category == category },
                                    userId: user.id
                                )) {
                                    CategoryCard(
                                        title: category,
                                        icon: iconForCategory(category),
                                        color: colorForCategory(category)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .padding(.bottom, 80) // Space for search bar
                    }
                }
            }
            .navigationTitle("Course Category")
            .navigationBarTitleDisplayMode(.large)
        }
        .id(user.id)
    }
    
    @ViewBuilder
    private func courseListView(courses: [Course], title: String, showSearch: Bool) -> some View {
        NavigationStack {
            ZStack {
                AppTheme.groupedBackground
                    .ignoresSafeArea(edges: .top)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Welcome header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(authService.entryPoint == .signup ? "Welcome," : "Welcome back,")
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
                                title: "Enrolled",
                                value: "\(viewModel.enrolledCourses.count)",
                                color: AppTheme.primaryBlue
                            )
                            
                            StatCard(
                                icon: "checkmark.seal.fill",
                                title: "Completed",
                                value: "\(viewModel.completedCoursesCount)",
                                color: AppTheme.successGreen
                            )
                        }
                        .padding(.horizontal)
                        // ✅ Upcoming Deadlines
                        if title == "My Courses" {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Upcoming Deadlines")
                                        .font(.title3.bold())
                                        .foregroundColor(AppTheme.primaryText)
                                    
                                    Spacer()
                                    
                                    if viewModel.upcomingDeadlines.isEmpty {
                                        Text("No deadlines")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                                
                                if viewModel.upcomingDeadlines.isEmpty {
                                    LearnerEmptyState(
                                        icon: "calendar",
                                        title: "No upcoming deadlines",
                                        message: "You're all caught up 🎉"
                                    )
                                    .padding(.horizontal)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(viewModel.upcomingDeadlines) { deadline in
                                                DeadlineCard(deadline: deadline)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.top, 6)
                        }
                        
                        
                        // Sort/Filter Options (scrollable to prevent truncation)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                Text(title == "My Courses" ? "Filter by" : "Sort by")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)
                                
                                if title == "My Courses" {
                                    ForEach(CourseEnrollmentFilter.allCases) { filter in
                                        Button(action: {
                                            withAnimation {
                                                viewModel.selectedEnrollmentFilter = filter
                                            }
                                        }) {
                                            Text(filter.rawValue)
                                                .font(.system(size: 14, weight: .medium))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(
                                                    viewModel.selectedEnrollmentFilter == filter ?
                                                    AppTheme.primaryBlue : Color.clear
                                                )
                                                .foregroundColor(
                                                    viewModel.selectedEnrollmentFilter == filter ?
                                                    .white : AppTheme.primaryBlue
                                                )
                                                .cornerRadius(16)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(AppTheme.primaryBlue, lineWidth: viewModel.selectedEnrollmentFilter == filter ? 0 : 1.5)
                                                )
                                        }
                                    }
                                } else {
                                    ForEach(CourseSortOption.allCases) { option in
                                        Button(action: {
                                            withAnimation {
                                                viewModel.selectedSortOption = option
                                            }
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: option.icon)
                                                    .font(.system(size: 12))
                                                Text(option.displayName)
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                viewModel.selectedSortOption == option ?
                                                AppTheme.primaryBlue :
                                                    Color.clear
                                            )
                                            .foregroundColor(
                                                viewModel.selectedSortOption == option ?
                                                    .white :
                                                    AppTheme.primaryBlue
                                            )
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(AppTheme.primaryBlue, lineWidth: viewModel.selectedSortOption == option ? 0 : 1.5)
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Course List
                        VStack(alignment: .leading, spacing: 16) {
                            Text(title)
                                .font(.title2.bold())
                                .foregroundColor(AppTheme.primaryText)
                                .padding(.horizontal)
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding()
                            } else {
                                let filteredCourses = getFilteredAndSortedCourses(from: courses, isMyCourses: title == "My Courses")
                                
                                if filteredCourses.isEmpty {
                                    LearnerEmptyState(
                                        icon: viewModel.searchText.isEmpty && viewModel.selectedCategory == nil ? "book.closed.fill" : "magnifyingglass",
                                        title: viewModel.searchText.isEmpty && viewModel.selectedCategory == nil ?
                                        (title == "Browse Courses" ? "No courses available" : "No enrollments yet") :
                                            "No courses found",
                                        message: viewModel.searchText.isEmpty && viewModel.selectedCategory == nil ?
                                        (title == "Browse Courses" ? "Check back later for new content" : "Browse available courses to start learning") :
                                            "Try adjusting your search or filters"
                                    )
                                    .padding(.horizontal)
                                } else {
                                    LazyVStack(spacing: 16) {
                                        ForEach(filteredCourses) { course in
                                            NavigationLink(destination:
                                                            LearnerCourseDetailView(
                                                                course: course,
                                                                isEnrolled: viewModel.isEnrolled(course),
                                                                userId: user.id,
                                                                onEnroll: {
                                                                    let success = await viewModel.enroll(course: course, userId: user.id)
                                                                    if success {
                                                                        dashboardRefreshTrigger = UUID()
                                                                        selectedTab = 1
                                                                    }
                                                                }
                                                            )
                                            ) {
                                                PublishedCourseCard(
                                                    course: course,
                                                    isEnrolled: viewModel.isEnrolled(course),
                                                    progress: viewModel.getCachedProgress(for: course.id),
                                                    onEnroll: {
                                                        let success = await viewModel.enroll(course: course, userId: user.id)
                                                        if success {
                                                            dashboardRefreshTrigger = UUID()
                                                            selectedTab = 1
                                                        }
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
                    }
                    .padding(.bottom, 100) // Large padding for tab bar
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 0)
            }
        }
        .id(user.id)
    }
    
    private func handleLogout() {
        Task {
            await authService.signOut()
        }
    }
    
    // Helper function (brought back from original to support filtering for both tabs)
    private func getFilteredAndSortedCourses(from courses: [Course], isMyCourses: Bool = false) -> [Course] {
        // 1. Apply search filter
        var filtered = courses
        if !viewModel.searchText.isEmpty {
            filtered = filtered.filter { course in
                course.title.localizedCaseInsensitiveContains(viewModel.searchText) ||
                course.description.localizedCaseInsensitiveContains(viewModel.searchText)
            }
        }
        
        // 2. Apply category filter
        if let category = viewModel.selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // 3. Apply Enrollment Filter if in "My Courses" tab
        if isMyCourses {
            filtered = viewModel.filteredEnrolledCourses.filter { enrolled in
                // Cross-reference with basic filters (search/category) applied above
                filtered.contains(where: { $0.id == enrolled.id })
            }
            return filtered // For "My Courses", we prioritize the enrollment filter
        }
        
        // 4. Apply sorting (Default for Browse tab)
        switch viewModel.selectedSortOption {
        case .relevance:
            // Sort by relevance: prioritize courses matching completed course categories/educators
            return filtered.sorted { course1, course2 in
                let score1 = relevanceScore(for: course1)
                let score2 = relevanceScore(for: course2)
                
                if score1 != score2 {
                    return score1 > score2 // Higher score first
                }
                // If same relevance score, sort by newest
                return course1.createdAt > course2.createdAt
            }
            
        case .popularity:
            // Sort by enrollment count (descending)
            print("DEBUG: Sorting by popularity")
            for course in filtered.prefix(5) {
                print("  - \(course.title): enrollmentCount=\(course.enrollmentCount)")
            }
            return filtered.sorted { course1, course2 in
                let count1 = course1.enrollmentCount
                let count2 = course2.enrollmentCount
                
                if count1 != count2 {
                    return count1 > count2
                }
                // If same enrollment count, sort by newest
                return course1.createdAt > course2.createdAt
            }
            
        case .newest:
            // Sort by creation date (newest first)
            print("DEBUG: Sorting by newest")
            for course in filtered.prefix(5) {
                print("  - \(course.title): createdAt=\(course.createdAt)")
            }
            return filtered.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    // Calculate relevance score based on completed courses
    private func relevanceScore(for course: Course) -> Int {
        var score = 0
        
        // +2 points if course category matches completed course categories
        if viewModel.completedCourseCategories.contains(course.category) {
            score += 2
        }
        
        // +1 point if course educator matches completed course educators
        if viewModel.completedCourseEducators.contains(course.educatorID) {
            score += 1
        }
        
        return score
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Programming": return "chevron.left.forwardslash.chevron.right"
        case "Design": return "paintbrush.fill"
        case "Business": return "briefcase.fill"
        case "Data Science": return "chart.bar.fill"
        case "Marketing": return "megaphone.fill"
        case "Photography": return "camera.fill"
        case "Music": return "music.note"
        case "Writing": return "pencil.and.outline"
        default: return "book.fill"
        }
    }
    
    // MARK: - Published Course Card
    
    struct PublishedCourseCard: View {
        let course: Course
        let isEnrolled: Bool
        let progress: Double                // 🔥 SINGLE SOURCE OF TRUTH
        var onEnroll: () async -> Void
        
        @Environment(\.colorScheme) var colorScheme
        @State private var isEnrolling = false
        @State private var showSuccess = false
        @State private var showPaymentRequired = false
        
        // MARK: - Category Styling
        
        private var categoryColor: Color {
            switch course.category.lowercased() {
            case "design": return AppTheme.accentPurple
            case "development", "programming", "code": return AppTheme.primaryBlue
            case "marketing": return AppTheme.warningOrange
            case "business": return AppTheme.accentTeal
            case "data", "analytics": return AppTheme.successGreen
            case "photography": return .pink
            case "music": return .indigo
            default: return AppTheme.secondaryText
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
        
        // MARK: - View
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                
                // Header
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.mediumCornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [categoryColor.opacity(0.2), categoryColor.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: categoryIcon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [categoryColor, categoryColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(course.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                            .lineLimit(2)
                        
                        Text(course.description)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryText)
                            .lineLimit(2)
                        
                        HStack(spacing: 10) {
                            Label(course.category, systemImage: "folder.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(categoryColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(categoryColor.opacity(0.12))
                                .cornerRadius(6)
                            
                            Label("\(course.modules.count)", systemImage: "list.bullet")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
                .padding(16)
                
                // Footer
                HStack {
                    if isEnrolled {
                        HStack(spacing: 12) {
                            MiniProgressRing(progress: progress)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                if progress >= 1.0 {
                                    Label("Completed", systemImage: "checkmark.seal.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppTheme.successGreen)
                                    
                                    Text("Certificate ready!")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.secondaryText)
                                } else {
                                    Text("In Progress")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppTheme.primaryText)
                                    
                                    Text("\(Int(progress * 100))% complete")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                            }
                        }
                        
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.secondaryText)
                        
                    } else {
                        // Price Label
                        if let price = course.price, price > 0 {
                            Text(price.formatted(.currency(code: "INR")))
                                .font(.headline)
                                .foregroundColor(AppTheme.primaryText)
                        } else {
                            Text("Free")
                                .font(.headline)
                                .foregroundColor(AppTheme.successGreen)
                        }
                        
                        Spacer()
                        
                        Button {
                            if let price = course.price, price > 0 {
                                showPaymentRequired = true
                            } else {
                                Task {
                                    isEnrolling = true
                                    await onEnroll()
                                    withAnimation {
                                        showSuccess = true
                                    }
                                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                                    showSuccess = false
                                    isEnrolling = false
                                }
                            }
                        } label: {
                            Group {
                                if showSuccess {
                                    Label("Enrolled!", systemImage: "checkmark.circle.fill")
                                } else if isEnrolling {
                                    ProgressView()
                                } else {
                                    Label("Enroll", systemImage: "plus.circle.fill")
                                }
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(showSuccess ? AppTheme.successGreen : .white)
                            .frame(width: 120, height: 36)
                            .background(
                                showSuccess ?
                                LinearGradient(colors: [AppTheme.successGreen.opacity(0.15), AppTheme.successGreen.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing) : AppTheme.oceanGradient
                            )
                            .cornerRadius(18)
                        }
                        .disabled(isEnrolling)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: AppTheme.cardShadow.color,
                    radius: AppTheme.cardShadow.radius,
                    x: AppTheme.cardShadow.x,
                    y: AppTheme.cardShadow.y)
            .alert("Payment Required", isPresented: $showPaymentRequired) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please open the course details to purchase this course.")
            }
        }
    }
    
    //
    //        private func loadProgress() {
    //            Task {
    //                courseProgress = await getCourseProgress(userId: userId, courseId: course.id)
    //                print("📊 Loaded progress for \(course.title): \(courseProgress * 100)%")
    //            }
    //        }
    //
    //        private func getCourseProgress(userId: UUID, courseId: UUID) async -> Double {
    //            do {
    //                let supabase = SupabaseManager.shared.client
    //
    //                // Fetch enrollment to get progress
    //                struct EnrollmentProgress: Codable {
    //                    let progress: Double?
    //                }
    //
    //                let enrollments: [EnrollmentProgress] = try await supabase
    //                    .from("enrollments")
    //                    .select("progress")
    //                    .eq("user_id", value: userId.uuidString)
    //                    .eq("course_id", value: courseId.uuidString)
    //                    .execute()
    //                    .value
    //
    //                return enrollments.first?.progress ?? 0.0
    //            } catch {
    //                print("❌ Error fetching progress: \(error)")
    //                return 0.0
    //            }
    //        }
    
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
    struct DeadlineCard: View {
        let deadline: CourseDeadline
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(AppTheme.primaryBlue)
                    
                    Spacer()
                    
                    Text(timeRemainingText(from: deadline.deadlineAt))
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.primaryBlue.opacity(0.12))
                        .foregroundColor(AppTheme.primaryBlue)
                        .cornerRadius(10)
                }
                
                Text(deadline.title)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(2)
                
                Text(deadline.deadlineAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .frame(width: 240)
            .background(AppTheme.secondaryGroupedBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        
        private func timeRemainingText(from date: Date) -> String {
            let interval = date.timeIntervalSinceNow
            if interval <= 0 { return "Due" }
            
            let hours = Int(interval / 3600)
            let days = hours / 24
            
            if days >= 1 { return "\(days)d left" }
            if hours >= 1 { return "\(hours)h left" }
            
            let mins = Int(interval / 60)
            return "\(max(mins, 1))m left"
        }
    }
    
    // Components are defined in separate files (LearnerDashboardComponents.swift, etc.)
    
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Programming": return Color(red: 0.2, green: 0.6, blue: 1.0)
        case "Design": return Color(red: 1.0, green: 0.4, blue: 0.6)
        case "Business": return Color(red: 0.4, green: 0.8, blue: 0.4)
        case "Marketing": return Color(red: 1.0, green: 0.6, blue: 0.2)
        case "Data Science": return Color(red: 0.6, green: 0.4, blue: 1.0)
        default: return AppTheme.primaryBlue
        }
    }
}
