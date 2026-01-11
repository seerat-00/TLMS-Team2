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
    @State private var isLoading = false
    @State private var selectedTab = 0
    @State private var showProfile = false
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var courseService = CourseService()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom tab selector
                    HStack(spacing: 0) {
                        TabButton(
                            title: "Educators",
                            icon: "person.badge.shield.checkmark.fill",
                            isSelected: selectedTab == 0,
                            badge: pendingEducators.count
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTab = 0
                            }
                        }
                        
                        TabButton(
                            title: "Courses",
                            icon: "book.fill",
                            isSelected: selectedTab == 1,
                            badge: pendingCourses.count
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTab = 1
                            }
                        }
                        
                        TabButton(
                            title: "Users",
                            icon: "person.3.fill",
                            isSelected: selectedTab == 2,
                            badge: nil
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTab = 2
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .background(AppTheme.groupedBackground)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            if selectedTab == 0 {
                                pendingEducatorsView
                            } else if selectedTab == 1 {
                                pendingCoursesView
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
    
    private var pendingCoursesView: some View {
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
        
        pendingEducators = await pending
        allUsers = await all
        pendingCourses = await courses
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
