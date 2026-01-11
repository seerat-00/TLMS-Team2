//
//  AuthenticationView.swift
//  TLMS-project-main
//
//  Main authentication coordinator
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isLoading {
                // Loading state
                ZStack {
                    AppTheme.groupedBackground
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryBlue))
                            .scaleEffect(1.5)
                        
                        Text("Loading...")
                            .foregroundColor(AppTheme.secondaryText)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            } else if authService.isAuthenticated, let user = authService.currentUser {
                if user.role == .admin && (user.passwordResetRequired ?? false) {
                    // Admin must change password
                    ChangePasswordView()
                } else {
                    // User is authenticated - route to appropriate dashboard
                    MainAppView(user: user)
                }
            } else {
                // Not authenticated - show login
                LoginView()
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthService())
}
