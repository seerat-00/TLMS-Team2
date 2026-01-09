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
                // Premium gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.98, green: 0.95, blue: 1.0),
                        Color(red: 0.95, green: 0.98, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Floating gradient blobs for glass effect depth
                GeometryReader { geometry in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: -100, y: -50)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.12), Color.pink.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 250, height: 250)
                        .blur(radius: 50)
                        .offset(x: geometry.size.width - 150, y: geometry.size.height - 200)
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
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
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showProfile = true }) {
                            Label("Profile", systemImage: "person.circle")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: handleLogout) {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .id(user.id)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Profile Photo Placeholder
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Text(user.fullName.prefix(1).uppercased())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // Welcome Text
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Welcome,")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.secondary)
                    
                    Text(user.fullName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                // Educator Badge
                HStack(spacing: 4) {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .font(.system(size: 12))
                    Text("Educator")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatGlassCard(
                icon: "book.fill",
                title: "Courses",
                value: "\(viewModel.totalCourses)",
                gradient: [Color.blue, Color.cyan]
            )
            
            StatGlassCard(
                icon: "person.3.fill",
                title: "Enrollments",
                value: "\(viewModel.totalEnrollments)",
                gradient: [Color.purple, Color.pink]
            )
        }
    }
    
    // MARK: - Courses Section
    
    private var coursesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Courses")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            
            if viewModel.recentCourses.isEmpty {
                EmptyCoursesCard()
            } else {
                ForEach(viewModel.recentCourses) { course in
                    CourseGlassCard(course: course)
                }
            }
        }
    }
    
    // MARK: - Create Course Button
    
    private var createCourseButton: some View {
        NavigationLink(destination: CreateCourseView(viewModel: CourseCreationViewModel(educatorID: user.id))) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                
                Text("Create New Course")
                    .font(.system(size: 18, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(.ultraThinMaterial)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(20)
            .shadow(color: .blue.opacity(0.4), radius: 20, x: 0, y: 10)
        }
        .padding(.top, 8)
    }
    
    private func handleLogout() {
        Task {
            await authService.signOut()
        }
    }
}

// MARK: - Stat Glass Card

struct StatGlassCard: View {
    let icon: String
    let title: String
    let value: String
    let gradient: [Color]
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Course Glass Card

struct CourseGlassCard: View {
    let course: DashboardCourse
    
    var body: some View {
        HStack(spacing: 16) {
            // Course Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: "book.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            
            // Course Info
            VStack(alignment: .leading, spacing: 6) {
                Text(course.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    // Status Badge
                    HStack(spacing: 4) {
                        Image(systemName: course.status.icon)
                            .font(.system(size: 10))
                        Text(course.status.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(course.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(course.status.color.opacity(0.15))
                    .cornerRadius(8)
                    
                    // Learner Count
                    if course.learnerCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                            Text("\(course.learnerCount)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Empty Courses Card

struct EmptyCoursesCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("No courses yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Create your first course to start teaching")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
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
