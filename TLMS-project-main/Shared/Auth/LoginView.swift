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
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.45),
                    Color(red: 0.2, green: 0.1, blue: 0.35),
                    Color(red: 0.15, green: 0.15, blue: 0.4)
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    animateGradient = true
                }
            }
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 60)
                    
                    // Logo and title
                    VStack(spacing: 16) {
                        Image(systemName: "graduationcap.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .white.opacity(0.3), radius: 20)
                        
                        Text("Welcome Back")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Sign in to continue learning")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
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
                        
                        // Error message
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Login button
                        Button(action: handleLogin) {
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
                            .shadow(color: Color(red: 0.4, green: 0.5, blue: 1).opacity(0.5), radius: 15, y: 8)
                        }
                        .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                        .opacity((authService.isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1)
                    }
                    .padding(.horizontal, 30)
                    
                    // Sign up link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button(action: { showSignup = true }) {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .font(.system(size: 16))
                    .padding(.top, 10)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .fullScreenCover(isPresented: $showSignup) {
            SignupView()
                .environmentObject(authService)
        }
    }
    
    private func handleLogin() {
        Task {
            let success = await authService.signIn(email: email, password: password)
            if success {
                // Navigation handled by AuthenticationView
            }
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
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
            }
            
            if showPasswordToggle {
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService())
}
