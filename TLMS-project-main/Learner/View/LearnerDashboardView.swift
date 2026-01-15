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
    @State private var searchText: String = ""
    @State private var selectedCategory: String? = nil
    
    @State private var showProfile = false
    @State private var showingError = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Browse Courses Tab
            courseListView(courses: publishedCourses, title: "Browse Courses", showSearch: false)
                .tabItem {
                    Label("Browse", systemImage: "book.fill")
                }
                .tag(0)
            
            // My Courses Tab
            courseListView(courses: enrolledCourses, title: "My Courses", showSearch: false)
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
        }
        .tint(AppTheme.primaryBlue)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .task {
            await loadData()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to enroll in course")
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
                                    courses: publishedCourses.filter { $0.category == category },
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
                    
                    // Bottom Search Bar (Apple TV style)
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 18))
                        
                        TextField("Search courses, topics and more", text: $searchText)
                            .textFieldStyle(.plain)
                            .autocapitalization(.none)
                            .font(.system(size: 16))
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(
                        AppTheme.secondaryGroupedBackground
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive, action: handleLogout) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                }
            }
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
                        
                        // Sort Options (scrollable to prevent truncation)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                Text("Sort by")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)
                                
                                ForEach(CourseSortOption.allCases) { option in
                                    Button(action: {
                                        withAnimation {
                                            selectedSortOption = option
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
                                            selectedSortOption == option ?
                                            AppTheme.primaryBlue :
                                            Color.clear
                                        )
                                        .foregroundColor(
                                            selectedSortOption == option ?
                                            .white :
                                            AppTheme.primaryBlue
                                        )
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(AppTheme.primaryBlue, lineWidth: selectedSortOption == option ? 0 : 1.5)
                                        )
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
                            
                            if isLoading {
                                ProgressView()
                                    .padding()
                            } else {
                                let filteredCourses = getFilteredAndSortedCourses(from: courses)
                                
                                if filteredCourses.isEmpty {
                                    EmptyStateView(
                                        icon: searchText.isEmpty && selectedCategory == nil ? "book.closed.fill" : "magnifyingglass",
                                        title: searchText.isEmpty && selectedCategory == nil ?
                                        (title == "Browse Courses" ? "No courses available" : "No enrollments yet") :
                                            "No courses found",
                                        message: searchText.isEmpty && selectedCategory == nil ?
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
                                                    isEnrolled: isEnrolled(course),
                                                    userId: user.id,
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
                    }
                    .padding(.bottom, 100) // Large padding for tab bar
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 0)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive, action: handleLogout) {
                        Label("Sign Out", systemImage: "arrow.right.square")
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
    
    private func getFilteredAndSortedCourses(from courses: [Course]) -> [Course] {
        // 1. Apply search filter
        var filtered = courses
        if !searchText.isEmpty {
            filtered = filtered.filter { course in
                course.title.localizedCaseInsensitiveContains(searchText) ||
                course.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 2. Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // 3. Apply sorting
        switch selectedSortOption {
        case .relevance:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .popularity:
            return filtered.sorted { $0.enrollmentCount > $1.enrollmentCount }
        case .newest:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        }
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
                                .truncationMode(.tail)
                        }
                        .foregroundColor(categoryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(categoryColor.opacity(0.15))
                        .cornerRadius(6)
                        .fixedSize()
                        
                        // Module Count
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 10))
                            Text("\(course.modules.count)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(AppTheme.secondaryText)
                        .fixedSize()
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
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
    
// MARK: - Category Chip

struct CategoryChip: View {
        let title: String
        let icon: String
        let isSelected: Bool
        let action: () -> Void
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                    
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isSelected ?
                    AppTheme.primaryBlue :
                        Color.clear
                )
                .foregroundColor(
                    isSelected ?
                        .white :
                        AppTheme.primaryBlue
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.primaryBlue, lineWidth: isSelected ? 0 : 1.5)
                )
            }
            .shadow(color: isSelected ? AppTheme.primaryBlue.opacity(0.3) : Color.clear, radius: isSelected ? 8 : 0, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
    
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
    
    // Preview removed due to circular reference with TabView structure
}

// MARK: - Category Card (Apple TV Style)

struct CategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient
            LinearGradient(
                colors: [color.opacity(0.8), color.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(16)
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.white.opacity(0.3))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(20)
            
            // Title
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.white)
                .padding(20)
        }
        .frame(height: 140)
        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Category Courses View

struct CategoryCoursesView: View {
    let category: String
    let courses: [Course]
    let userId: UUID
    @Environment(\.dismiss) var dismiss
    @StateObject private var courseService = CourseService()
    @State private var enrolledCourseIds: Set<UUID> = []
    
    var body: some View {
        ZStack {
            AppTheme.groupedBackground
                .ignoresSafeArea(edges: .top)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    if courses.isEmpty {
                        EmptyStateView(
                            icon: "book.closed.fill",
                            title: "No Courses Yet",
                            message: "Check back later for \(category) courses"
                        )
                        .padding(.top, 60)
                    } else {
                        ForEach(courses) { course in
                            NavigationLink(destination:
                                LearnerCourseDetailView(
                                    course: course,
                                    isEnrolled: enrolledCourseIds.contains(course.id),
                                    userId: userId,
                                    onEnroll: {}
                                )
                            ) {
                                CategoryCourseCard(
                                    course: course,
                                    isEnrolled: enrolledCourseIds.contains(course.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Category Course Card

struct CategoryCourseCard: View {
    let course: Course
    let isEnrolled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Course Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(course.categoryColor.opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Image(systemName: course.categoryIcon)
                    .font(.system(size: 28))
                    .foregroundColor(course.categoryColor)
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
                    // Category Badge
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 10))
                        Text(course.category)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundColor(course.categoryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(course.categoryColor.opacity(0.15))
                    .cornerRadius(6)
                    .fixedSize()
                    
                    // Module Count
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 10))
                        Text("\(course.modules.count)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .fixedSize()
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Enrollment Status / Arrow
            if isEnrolled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.successGreen)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
