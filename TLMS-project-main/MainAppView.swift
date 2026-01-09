//
//  MainAppView.swift
//  TLMS-project-main
//
//  Main app view that routes to role-specific dashboards
//

import SwiftUI

struct MainAppView: View {
    let user: User
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            switch user.role {
            case .learner:
                LearnerRootView(user: user)
            case .educator:
                EducatorDashboardView(user: user)
            case .admin:
                AdminDashboardView(user: user)
            }
        }
    }
}

#Preview {
    MainAppView(user: User(
        id: UUID(),
        email: "test@example.com",
        fullName: "Test User",
        role: .learner,
        approvalStatus: .approved,
        resumeUrl: nil,
        passwordResetRequired: false,
        createdAt: Date(),
        updatedAt: Date()
    ))
    .environmentObject(AuthService())
}
