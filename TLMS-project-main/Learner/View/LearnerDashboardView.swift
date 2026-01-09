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
    @State private var showProfile = false
    @Environment(\.colorScheme) var colorScheme
    
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
                                value: "0",
                                color: Color(red: 0.4, green: 0.5, blue: 1)
                            )
                            
                            StatCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Progress",
                                value: "0%",
                                color: Color(red: 0.5, green: 0.3, blue: 0.9)
                            )
                        }
                        .padding(.horizontal)
                        
                        // Course sections
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Continue Learning")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                            
                            // Placeholder for courses
                            VStack(spacing: 12) {
                                EmptyStateView(
                                    icon: "book.closed.fill",
                                    title: "No courses yet",
                                    message: "Start exploring courses to begin your learning journey"
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 40)
                    }
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
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 1))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .id(user.id)
    }
    
    private func handleLogout() {
        Task {
            await authService.signOut()
        }
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
                .font(.system(size: 28))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: color.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 15, y: 5)
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
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 10, y: 5)
        )
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

