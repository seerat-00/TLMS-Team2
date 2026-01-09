//
//  ChangePasswordView.swift
//  TLMS-project-main
//
//  Forces user to change password on first login
//

import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject var authService: AuthService
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var validationError: String?
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.1, green: 0.2, blue: 0.45)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                        
                    Text("Change Password")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        
                    Text("For security reasons, you must change your password before continuing.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Form
                VStack(spacing: 20) {
                    CustomTextField(
                        icon: "lock.fill",
                        placeholder: "New Password",
                        text: $newPassword,
                        isSecure: !showPassword,
                        showPasswordToggle: true,
                        showPassword: $showPassword
                    )
                    
                    CustomTextField(
                        icon: "lock.fill",
                        placeholder: "Confirm New Password",
                        text: $confirmPassword,
                        isSecure: !showConfirmPassword,
                        showPasswordToggle: true,
                        showPassword: $showConfirmPassword
                    )
                    
                    if let error = validationError ?? authService.errorMessage {
                        Text(error)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: handleChangePassword) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Update Password")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
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
                    }
                    .disabled(authService.isLoading || newPassword.isEmpty || confirmPassword.isEmpty)
                    .opacity((authService.isLoading || newPassword.isEmpty || confirmPassword.isEmpty) ? 0.6 : 1)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .padding(.top, 60)
        }
    }
    
    private func handleChangePassword() {
        validationError = nil
        
        guard newPassword == confirmPassword else {
            validationError = "Passwords do not match"
            return
        }
        
        guard newPassword.count >= 6 else {
            validationError = "Password must be at least 6 characters"
            return
        }
        
        Task {
            let success = await authService.updatePassword(newPassword: newPassword)
            if success {
                // Success is handled by AuthService updating the user state,
                // which will trigger AuthenticationView to redirect
            }
        }
    }
}

#Preview {
    ChangePasswordView()
        .environmentObject(AuthService())
}
