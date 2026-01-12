//
//  LoginView.swift
//  TLMS-project-main
//
//  Premium login page with role selection
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showSignup = false
    @State private var showOTPVerification = false
    @State private var animateGradient = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        Spacer(minLength: 60)
                        
                        // Logo and title
                        VStack(spacing: 16) {
                            Image(systemName: "graduationcap.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(AppTheme.primaryBlue)
                                .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 10)
                            
                            Text("Welcome Back")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.primaryText)
                            
                            Text("Sign in to continue learning")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .padding(.bottom, 20)
                        
                        // Login form
                        VStack(spacing: 20) {
                            // Email field
                            CustomTextField(
                                icon: "envelope.fill",
                                placeholder: "Email",
                                text: $email,
                                isSecure: false
                            )
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            
                            // Password field
                            CustomTextField(
                                icon: "lock.fill",
                                placeholder: "Password",
                                text: $password,
                                isSecure: !showPassword,
                                showPasswordToggle: true,
                                showPassword: $showPassword
                            )
                            
                            // 2FA Info message
                            HStack(spacing: 8) {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.green.opacity(0.8))
                                Text("2-Step Verification: Code will be sent to your email")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal)
                            
                            // Error message
                            if let errorMessage = authService.errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.errorRed)
                                    .padding(.horizontal)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Login button
                            Button(action: {
                                print("🚀 BUTTON PRESSED!")
                                handleLogin()
                            }) {
                                HStack {
                                    if authService.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Sign In")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(AppTheme.primaryBlue)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.cornerRadius)
                                .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 8, y: 4)
                            }
                            .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                            .opacity((authService.isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1)
                        }
                        .padding(.horizontal, 30)
                        
                        // Sign up link
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(AppTheme.secondaryText)
                            
                            Button(action: { showSignup = true }) {
                                Text("Sign Up")
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppTheme.primaryBlue)
                            }
                        }
                        .font(.system(size: 16))
                        .padding(.top, 10)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationDestination(isPresented: $showSignup) {
                SignupView()
            }
        }
    }
    
    private func handleLogin() {
        Task {
            print("� Starting 2FA login...")
            
            // Store password for later verification
            authService.setPendingPassword(password)
            
            // Send OTP - AuthenticationView will show OTP screen automatically
            let success = await authService.sendOTP(email: email)
            print("📧 OTP sent: \(success)")
        }
    }
}

// MARK: - Custom Text Field Component

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var showPasswordToggle: Bool = false
    @Binding var showPassword: Bool
    
    init(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool = false, showPasswordToggle: Bool = false, showPassword: Binding<Bool> = .constant(false)) {
        self.icon = icon
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.showPasswordToggle = showPasswordToggle
        self._showPassword = showPassword
    }
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.secondaryText)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(AppTheme.primaryText)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(AppTheme.primaryText)
            }
            
            if showPasswordToggle {
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
        .padding()
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService())
}
