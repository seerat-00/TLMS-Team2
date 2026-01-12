//
//  SignupView.swift
//  TLMS-project-main
//
//  Premium signup page with role selection
//

import SwiftUI
import UniformTypeIdentifiers

struct SignupView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRole: UserRole = .learner
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var animateGradient = false
    @State private var showSuccessMessage = false
    @State private var validationError: String?
    
    // Resume upload
    @State private var showDocumentPicker = false
    @State private var selectedResumeURL: URL?
    @State private var selectedResumeData: Data?
    @State private var selectedResumeFileName: String?
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.groupedBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Logo and title
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                            .font(.system(size: 70))
                            .foregroundColor(AppTheme.primaryBlue)
                            .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 10)
                        
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("Join our learning community")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(.bottom, 10)
                    
                    // Signup form
                    VStack(spacing: 18) {
                        // Full name field
                        CustomTextField(
                            icon: "person.fill",
                            placeholder: "Full Name",
                            text: $fullName
                        )
                        .textInputAutocapitalization(.words)
                        
                        // Email field
                        CustomTextField(
                            icon: "envelope.fill",
                            placeholder: "Email",
                            text: $email
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
                        
                        // Confirm password field
                        CustomTextField(
                            icon: "lock.fill",
                            placeholder: "Confirm Password",
                            text: $confirmPassword,
                            isSecure: !showConfirmPassword,
                            showPasswordToggle: true,
                            showPassword: $showConfirmPassword
                        )
                        
                        // Role selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("I am a:")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                            
                            HStack(spacing: 12) {
                                RoleButton(
                                    role: .learner,
                                    icon: "book.fill",
                                    isSelected: selectedRole == .learner
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedRole = .learner
                                    }
                                }
                                
                                RoleButton(
                                    role: .educator,
                                    icon: "person.fill.checkmark",
                                    isSelected: selectedRole == .educator
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedRole = .educator
                                    }
                                }
                            }
                        }
                        
                        // Resume upload for educators
                        if selectedRole == .educator {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upload Resume (PDF/DOC)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryText)
                                
                                Button(action: { showDocumentPicker = true }) {
                                    HStack {
                                        Image(systemName: selectedResumeFileName != nil ? "checkmark.circle.fill" : "doc.fill")
                                            .font(.system(size: 20))
                                        
                                        Text(selectedResumeFileName ?? "Choose File")
                                            .font(.system(size: 16, weight: .medium))
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                    }
                                    .foregroundColor(AppTheme.primaryText)
                                    .padding()
                                    .background(AppTheme.secondaryGroupedBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppTheme.secondaryText.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                            .transition(.scale.combined(with: .opacity))
                            
                            // Educator approval notice
                            HStack(spacing: 10) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(AppTheme.warningOrange)
                                
                                Text("Educator accounts require admin approval. Upload your resume for verification.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .background(AppTheme.warningOrange.opacity(0.1))
                            .cornerRadius(12)
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Validation error
                        if let validationError = validationError {
                            Text(validationError)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.errorRed)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Auth service error
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.errorRed)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Success message
                        if showSuccessMessage {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppTheme.successGreen)
                                
                                if selectedRole == .educator {
                                    Text("Account created! Pending admin approval.")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(AppTheme.primaryText)
                                        .multilineTextAlignment(.center)
                                } else {
                                    Text("Account created successfully!")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(AppTheme.primaryText)
                                }
                            }
                            .padding()
                            .background(AppTheme.successGreen.opacity(0.1))
                            .cornerRadius(12)
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Sign up button
                        Button(action: handleSignup) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Create Account")
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
                        .disabled(authService.isLoading || !isFormValid)
                        .opacity((authService.isLoading || !isFormValid) ? 0.6 : 1)
                    }
                    .padding(.horizontal, 30)
                    
                    // Login link
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(AppTheme.secondaryText)
                        
                        Button(action: { dismiss() }) {
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.primaryBlue)
                        }
                    }
                    .font(.system(size: 16))
                    .padding(.top, 5)
                    
                    Spacer(minLength: 30)
                }
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(
                selectedURL: $selectedResumeURL,
                selectedData: $selectedResumeData,
                selectedFileName: $selectedResumeFileName
            )
        }
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty && !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
    }
    
    private func handleSignup() {
        // Validate form
        validationError = nil
        
        guard password == confirmPassword else {
            validationError = "Passwords do not match"
            return
        }
        
        guard password.count >= 6 else {
            validationError = "Password must be at least 6 characters"
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            validationError = "Please enter a valid email address"
            return
        }
        
        // Sign up
        Task {
            let success = await authService.signUp(
                email: email,
                password: password,
                fullName: fullName,
                role: selectedRole,
                resumeData: selectedResumeData,
                resumeFileName: selectedResumeFileName
            )
            
            if success {
                withAnimation {
                    showSuccessMessage = true
                }
                
                // Auto-dismiss for learners, show message for educators
                if selectedRole == .learner {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                } else {
                    // For educators, show message for longer
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Role Selection Button

struct RoleButton: View {
    let role: UserRole
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : AppTheme.primaryBlue)
                
                Text(role.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppTheme.primaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(isSelected ? AppTheme.primaryBlue : AppTheme.secondaryGroupedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(
                        isSelected ? AppTheme.primaryBlue : AppTheme.primaryBlue.opacity(0.3),
                        lineWidth: isSelected ? 0 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(
                color: isSelected ? AppTheme.primaryBlue.opacity(0.3) : Color.black.opacity(0.05),
                radius: isSelected ? 8 : 2,
                y: isSelected ? 4 : 1
            )
        }
    }
}

#Preview {
    SignupView()
        .environmentObject(AuthService())
}

