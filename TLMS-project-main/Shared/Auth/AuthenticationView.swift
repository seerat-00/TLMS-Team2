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
            if authService.otpSent && !authService.isAuthenticated {
                // Show OTP verification screen (before authentication completes)
                OTPVerificationView(email: authService.pendingEmail ?? "")
                    .environmentObject(authService)
            } else if authService.isLoading {
                // Loading state
                ZStack {
                    AppTheme.groupedBackground
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryAccent))
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
                        .task {
                            await NotificationManager.shared.requestPermission()
                        }

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
