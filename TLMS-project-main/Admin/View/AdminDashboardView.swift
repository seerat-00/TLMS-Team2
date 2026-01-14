//
//  AdminDashboardView.swift
//  TLMS-project-main
//
//  Dashboard for admin users with educator approval management
//

import SwiftUI

struct AdminDashboardView: View {
    let user: User
    @EnvironmentObject var authService: AuthService
    @State private var pendingEducators: [User] = []
    @State private var pendingCourses: [Course] = []
    @State private var allUsers: [User] = []
    @State private var activeCourses: [Course] = []
    @State private var allEnrollments: [Enrollment] = []
    
    @State private var isLoading = false
    @State private var selectedTab = 0
    @State private var showProfile = false
    @State private var selectedTimeFilter: AnalyticsTimeFilter = .last30Days
    
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var courseService = CourseService()
    
    // Feature Flags
    private let isRevenueEnabled = false
    
    // Computed Stats
    var filteredRevenue: Double {
        let filtered = allEnrollments.filter {
            if let date = $0.enrolledAt {
                return selectedTimeFilter.isDateInPeriod(date)
            }
            return false // Exclude if no date (or true for allTime?)
            // If allTime, we want to include even if nil?
            // selectedTimeFilter.isDateInPeriod handles logic.
            // If nil, we can't check. 
            // Let's assume nil = old or unknown.
            // If .allTime, we might want everything.
        }
        
        let coursePriceMap = Dictionary(uniqueKeysWithValues: activeCourses.map { ($0.id, $0.price ?? 0) })
        return filtered.reduce(0) { total, enrollment in
            total + (coursePriceMap[enrollment.courseID] ?? 0)
        }
    }
    
    var filteredCoursesCount: Int {
        // Filter courses by createdAt?
        // "Total Courses" usually implies *current* inventory. 
        // But "Filter Analytics" might mean "New courses added in this period"?
        // Requirement says "Filter dashboard data".
        // Usually Platform Summary counts stand for "Current State".
        // Revenue is definitely time-sensitive.
        // User Growth (Learners/Educators) is time-sensitive (Registered in period).
        // I will filter Courses and Users by `createdAt`.
        activeCourses.filter { selectedTimeFilter.isDateInPeriod($0.createdAt) }.count
    }
    
    var filteredLearnersCount: Int {
        allUsers.filter { $0.role == .learner && selectedTimeFilter.isDateInPeriod($0.createdAt) }.count
    }
    
    var filteredEducatorsCount: Int {
        allUsers.filter { $0.role == .educator && selectedTimeFilter.isDateInPeriod($0.createdAt) }.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Content with scrollable tabs
                ScrollView {
                    VStack(spacing: 0) {
                        // Header & Filter
                        HStack {
                            Text("Overview")
                                .font(.title2.bold())
                            Spacer()
                            Picker("Time Period", selection: $selectedTimeFilter) {
                                ForEach(AnalyticsTimeFilter.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Summary Stats
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                StatCard(
                                    icon: "banknote.fill",
                                    title: "Total Revenue",
                                    value: isRevenueEnabled ? filteredRevenue.formatted(.currency(code: "INR")) : "--",
                                    color: AppTheme.successGreen
                                )
                                .frame(width: 180)
                                
                                let split = RevenueCalculator.calculateSplit(total: filteredRevenue)
                                
                                StatCard(
                                    icon: "building.columns.fill",
                                    title: "Admin (20%)",
                                    value: isRevenueEnabled ? split.admin.formatted(.currency(code: "INR")) : "--",
                                    color: AppTheme.primaryBlue
                                )
                                .frame(width: 160)
                                
                                StatCard(
                                    icon: "person.crop.circle.badge.checkmark",
                                    title: "Educators (80%)",
                                    value: isRevenueEnabled ? split.educator.formatted(.currency(code: "INR")) : "--",
                                    color: Color.purple
                                )
                                .frame(width: 160)
                                
                                StatCard(
                                    icon: "book.fill",
                                    title: "Courses",
                                    value: "\(filteredCoursesCount)",
                                    color: .orange
                                )
                                .frame(width: 160)
                                
                                StatCard(
                                    icon: "person.2.fill",
                                    title: "Learners",
                                    value: "\(filteredLearnersCount)",
                                    color: AppTheme.successGreen
                                )
                                .frame(width: 160)
                                
                                StatCard(
                                    icon: "graduationcap.fill",
                                    title: "Educators",
                                    value: "\(filteredEducatorsCount)",
                                    color: .orange
                                )
                                .frame(width: 160)
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                        }
                        
                        // Analytics Charts
                        let split = RevenueCalculator.calculateSplit(total: filteredRevenue)
                        AdminAnalyticsView(
                            totalRevenue: filteredRevenue,
                            adminRevenue: split.admin,
                            educatorRevenue: split.educator,
                            totalLearners: filteredLearnersCount,
                            totalEducators: filteredEducatorsCount,
                            showRevenue: isRevenueEnabled
                        )
                        .padding(.top, 20)
                        
                        // Tab Selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Management")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            Picker("Section", selection: $selectedTab) {
                                Text("Educators (\(pendingEducators.count))").tag(0)
                                Text("Courses (\(pendingCourses.count))").tag(1)
                                Text("Users").tag(2)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 10)
                        
                        // Tab content
                        VStack(spacing: 20) {
                            if selectedTab == 0 {
                                pendingEducatorsView
                            } else if selectedTab == 1 {
                                coursesTabView
                            } else {
                                allUsersView
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showProfile = true }) {
                            Label("Profile", systemImage: "person.circle")
                        }
                        
                        Button(action: refreshData) {
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
    
    // MARK: - Pending Educators View
    
    private var pendingEducatorsView: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(40)
            } else if pendingEducators.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "No pending educators",
                    message: "All educator requests have been reviewed"
                )
            } else {
                ForEach(pendingEducators) { educator in
                    PendingEducatorCard(educator: educator) {
                        await approveEducator(educator)
                    } onReject: {
                        await rejectEducator(educator)
                    }
                }
            }
        }
    }
    
    // MARK: - Pending Courses View
    
    @State private var courseTabMode = 0 // 0: Pending, 1: Monitor
    
    // MARK: - Courses Tab View
    
    private var coursesTabView: some View {
        VStack(spacing: 16) {
            // Sub-navigation for Courses
            Picker("Mode", selection: $courseTabMode) {
                Text("Pending Review").tag(0)
                Text("Value Monitor").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            if courseTabMode == 0 {
                pendingCoursesList
            } else {
                AdminCourseValueView()
            }
        }
    }
    
    private var pendingCoursesList: some View {
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
                            await loadData()
                        }
                    })) {
                        PendingCourseCard(course: course)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - All Users View
    
    private var allUsersView: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(40)
            } else if allUsers.isEmpty {
                EmptyStateView(
                    icon: "person.3.fill",
                    title: "No users yet",
                    message: "Users will appear here once they sign up"
                )
            } else {
                ForEach(allUsers) { user in
                    UserCard(user: user)
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        isLoading = true
        async let pending = authService.fetchPendingEducators()
        async let all = authService.fetchAllUsers()
        async let courses = courseService.fetchPendingCourses()
        async let activeCourses = courseService.fetchAllActiveCourses()
        async let allEnrollments = courseService.fetchAllEnrollments()
        
        let (pendingRes, allRes, coursesRes, activeRes, enrollmentsRes) = await (pending, all, courses, activeCourses, allEnrollments)
        
        pendingEducators = pendingRes
        allUsers = allRes
        pendingCourses = coursesRes
        self.activeCourses = activeRes
        self.allEnrollments = enrollmentsRes
        
        isLoading = false
    }
    
    private func refreshData() {
        Task {
            await loadData()
        }
    }
    
    // MARK: - Actions
    
    private func approveEducator(_ educator: User) async {
        let success = await authService.approveEducator(userId: educator.id)
        if success {
            await loadData()
        }
    }
    
    private func rejectEducator(_ educator: User) async {
        let success = await authService.rejectEducator(userId: educator.id)
        if success {
            await loadData()
        }
    }
    
    private func handleLogout() {
        Task {
            await authService.signOut()
        }
    }
}

// MARK: - Pending Course Card

struct PendingCourseCard: View {
    let course: Course
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.primaryBlue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "book.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.primaryBlue)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Text(course.category)
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppTheme.primaryBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.primaryBlue.opacity(0.1))
                    .cornerRadius(6)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(16)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Tab Button Component

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let badge: Int?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                    
                    if let badge = badge, badge > 0 {
                        Text("\(badge)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.warningOrange)
                            .clipShape(Capsule())
                    }
                }
                .foregroundColor(isSelected ? AppTheme.primaryBlue : AppTheme.secondaryText)
                
                Rectangle()
                    .fill(isSelected ? AppTheme.primaryBlue : Color.clear)
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pending Educator Card

struct PendingEducatorCard: View {
    let educator: User
    let onApprove: () async -> Void
    let onReject: () async -> Void
    @State private var isProcessing = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User info
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.5, blue: 1),
                                Color(red: 0.5, green: 0.3, blue: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(educator.fullName.prefix(1)))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(educator.fullName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(educator.email)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("Applied \(educator.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Resume download button
            if let resumeUrl = educator.resumeUrl {
                Link(destination: URL(string: resumeUrl)!) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 16))
                        
                        Text("View Resume")
                            .font(.system(size: 15, weight: .medium))
                        
                        Spacer()
                        
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 1))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.4, green: 0.5, blue: 1).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 0.4, green: 0.5, blue: 1).opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                    
                    Text("No resume uploaded")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.1))
                )
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        isProcessing = true
                        await onReject()
                        isProcessing = false
                    }
                }) {
                    Text("Reject")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red, lineWidth: 2)
                        )
                }
                .disabled(isProcessing)
                
                Button(action: {
                    Task {
                        isProcessing = true
                        await onApprove()
                        isProcessing = false
                    }
                }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Approve")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.5, blue: 1),
                                Color(red: 0.5, green: 0.3, blue: 0.9)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isProcessing)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 10, y: 5)
        )
    }
}

// MARK: - User Card

struct UserCard: View {
    let user: User
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(roleColor)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(user.fullName.prefix(1)))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(user.email)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Text(user.role.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(roleColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(roleColor.opacity(0.15))
                        .cornerRadius(6)
                    
                    if user.role == .educator {
                        Text(user.approvalStatus.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.15))
                            .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 5, y: 2)
        )
    }
    
    private var roleColor: Color {
        switch user.role {
        case .learner: return Color(red: 0.4, green: 0.5, blue: 1)
        case .educator: return Color(red: 0.5, green: 0.3, blue: 0.9)
        case .admin: return Color(red: 0.9, green: 0.3, blue: 0.3)
        }
    }
    
    private var statusColor: Color {
        switch user.approvalStatus {
        case .approved: return .green
        case .pending: return .orange
        case .rejected: return .red
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

#Preview {
    AdminDashboardView(user: User(
        id: UUID(),
        email: "admin@example.com",
        fullName: "Admin User",
        role: .admin,
        approvalStatus: .approved,
        resumeUrl: nil,
        passwordResetRequired: false,
        createdAt: Date(),
        updatedAt: Date()
    ))
    .environmentObject(AuthService())
}
