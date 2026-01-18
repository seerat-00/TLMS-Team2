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
    @StateObject private var viewModel = LearnerDashboardViewModel()
    @State private var selectedTab = 0 // 0: Browse, 1: My Courses
    
    @State private var showProfile = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Browse Courses Tab
            courseListView(courses: viewModel.publishedCourses, title: "Browse Courses", showSearch: false)
                .tabItem {
                    Label("Browse", systemImage: "book.fill")
                }
                .tag(0)
            
            // My Courses Tab
            courseListView(courses: viewModel.enrolledCourses, title: "My Courses", showSearch: false)
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
            await viewModel.loadData(userId: user.id)
        }
        .alert("Error", isPresented: $viewModel.showingError) {
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
                    
                    // Bottom Search Bar (Apple TV style)
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 18))
                        
                        TextField("Search courses, topics and more", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .autocapitalization(.none)
                            .font(.system(size: 16))
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: { viewModel.searchText = "" }) {
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
                                value: "\(viewModel.enrolledCourses.count)",
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
                                // Use filteredCourses if we are browsing (showing published courses),
                                // but for "My Courses" we might want to show all or filter them too.
                                // The original code used `getFilteredAndSortedCourses(from: courses)`.
                                // However, in the ViewModel I implemented `filteredCourses` which uses `publishedCourses`.
                                // This assumes the main view is filtering published courses.
                                // For "My Courses", we might want the same filtering logic applied to `enrolledCourses`.
                                // But `filteredCourses` in VM is hardcoded to `publishedCourses`.
                                // Let's adjust: I'll manually filter here using VM logic if needed, or better,
                                // the VM should probably expose a method to filter ANY list.
                                // Or simpler: `getFilteredAndSortedCourses` logic was moved to `filteredCourses` property.
                                // If I use `viewModel.filteredCourses` here, it is based on `publishedCourses`.
                                // So for "My Courses" tab, if I want to search/sort, I need to apply it to `enrolledCourses`.
                                //
                                // Wait, the original View called `getFilteredAndSortedCourses(from: courses)` where `courses` was passed in.
                                // I should keep a helper in View or use VM method.
                                // Since I can't easily change VM interface right now without another step,
                                // I will bring back the filtering helper (modified to use VM state) or
                                // check if `courses` argument is `publishedCourses`?
                                // If `courses` == `viewModel.publishedCourses`, use `viewModel.filteredCourses`.
                                // But `courses` is passed by value (copy) or ref.
                                //
                                // Actually, simpler solution: implement `getFilteredAndSortedCourses` locally using VM state,
                                // just like before, but accessing `viewModel.searchText` etc.
                                // This keeps behavior identical for "My Courses" too.

                                let filteredCourses = getFilteredAndSortedCourses(from: courses)
                                
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
                                                            selectedTab = 1
                                                        }
                                                    }
                                                )
                                            ) {
                                                PublishedCourseCard(
                                                    course: course,
                                                    isEnrolled: viewModel.isEnrolled(course),
                                                    onEnroll: {
                                                        let success = await viewModel.enroll(course: course, userId: user.id)
                                                        if success {
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
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 0)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showProfile = true }) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 24))
                                .foregroundColor(AppTheme.primaryBlue)
                        }
                        
                        Button(role: .destructive, action: handleLogout) {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    }
                }
            }
        }
        .id(user.id)
        .sheet(isPresented: $showProfile) {
            ProfileView(user: user)
        }
        .task {
            // Data loading is handled at top level, but maybe refresh here?
            // Original code had .task { await loadData() } on TabView AND inside courseListView?
            // Original line 295: .task { await loadData() } on NavigationStack in courseListView.
            // Original line 54: .task { await loadData() } on TabView.
            // Duplicate calls. I'll stick to top level or maybe both is fine (idempotent-ish).
        }
    }
    
    private func handleLogout() {
        Task {
            await authService.signOut()
        }
    }
    
    // Helper function (brought back from original to support filtering for both tabs)
    private func getFilteredAndSortedCourses(from courses: [Course]) -> [Course] {
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
        
        // 3. Apply sorting
        switch viewModel.selectedSortOption {
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
                                .font(.caption.weight(.medium))
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
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        .fixedSize()
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Enroll Action
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
    

// MARK: - Components
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


