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
                    Color(red: 0.1, green: 0.2, blue: 0.45)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Loading...")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            } else if authService.isAuthenticated, let user = authService.currentUser {
                // User is authenticated - route to appropriate dashboard
                MainAppView(user: user)
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
