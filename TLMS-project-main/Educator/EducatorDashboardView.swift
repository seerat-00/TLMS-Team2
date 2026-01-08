//
//  EducatorDashboardView.swift
//  TLMS-project-main
//
//  Dashboard for educator users
//

import SwiftUI

struct EducatorDashboardView: View {
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
                            Text("Educator Dashboard")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text(user.fullName)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Approval status
                        if user.approvalStatus == .pending {
                            PendingApprovalBanner()
                                .padding(.horizontal)
                        } else if user.approvalStatus == .rejected {
                            RejectedBanner()
                                .padding(.horizontal)
                        } else {
                            // Approved - show educator features
                            VStack(spacing: 20) {
                                // Quick stats
                                HStack(spacing: 16) {
                                    StatCard(
                                        icon: "book.fill",
                                        title: "Courses",
                                        value: "0",
                                        color: Color(red: 0.4, green: 0.5, blue: 1)
                                    )
                                    
                                    StatCard(
                                        icon: "person.3.fill",
                                        title: "Students",
                                        value: "0",
                                        color: Color(red: 0.5, green: 0.3, blue: 0.9)
                                    )
                                }
                                .padding(.horizontal)
                                
                                // Create course button
                                Button(action: {}) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                        
                                        Text("Create New Course")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
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
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .shadow(color: Color(red: 0.4, green: 0.5, blue: 1).opacity(0.3), radius: 15, y: 5)
                                }
                                .padding(.horizontal)
                                
                                // Courses section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("My Courses")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal)
                                    
                                    EmptyStateView(
                                        icon: "book.closed.fill",
                                        title: "No courses yet",
                                        message: "Create your first course to start teaching"
                                    )
                                    .padding(.horizontal)
                                }
                            }
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
    }
    
    private func handleLogout() {
        Task {
            await authService.signOut()
        }
    }
}

// MARK: - Pending Approval Banner

struct PendingApprovalBanner: View {
    @Environment(\.colorScheme) var colorScheme
    
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
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .orange.opacity(colorScheme == .dark ? 0.3 : 0.2), radius: 15, y: 5)
        )
    }
}

// MARK: - Rejected Banner

struct RejectedBanner: View {
    @Environment(\.colorScheme) var colorScheme
    
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
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .red.opacity(colorScheme == .dark ? 0.3 : 0.2), radius: 15, y: 5)
        )
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
        createdAt: Date(),
        updatedAt: Date()
    ))
    .environmentObject(AuthService())
}
