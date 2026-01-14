//
//  OTPVerificationView.swift
//  TLMS-project-main
//
//  OTP verification screen for 2FA
//

import SwiftUI

struct OTPVerificationView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    let email: String
    
    @State private var otpCode = ""
    @State private var resendCountdown = 60
    @State private var canResend = false
    @FocusState private var isCodeFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient Background
                AppTheme.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer(minLength: 40)
                        
                        // Icon
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.primaryBlue)
                            .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 10)
                            .padding(.bottom, 10)
                        
                        // Title
                        VStack(spacing: 8) {
                            Text("Enter Verification Code")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.primaryText)
                            
                            Text("We sent an 8-digit code to")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.secondaryText)
                            
                            Text(email)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.primaryBlue)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.bottom, 10)
                        
                        // OTP Input - 8 individual boxes
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                ForEach(0..<8, id: \.self) { index in
                                    OTPDigitBox(
                                        digit: getDigit(at: index),
                                        isFocused: otpCode.count == index
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .onTapGesture {
                                // Tap on boxes to trigger keyboard
                                isCodeFieldFocused = true
                            }
                            
                            // Hidden text field for keyboard input
                            TextField("", text: $otpCode)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .focused($isCodeFieldFocused)
                                .opacity(0)
                                .frame(height: 1)
                                .onChange(of: otpCode) { oldValue, newValue in
                                    // Limit to 8 digits
                                    if newValue.count > 8 {
                                        otpCode = String(newValue.prefix(8))
                                    }
                                    // Auto-verify when 8 digits entered
                                    if newValue.count == 8 {
                                        Task {
                                            await verifyCode()
                                        }
                                    }
                                }
                            
                            Text("\(otpCode.count)/8")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.secondaryText.opacity(0.7))
                        }
                        
                        // Error message
                        if let errorMessage = authService.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(errorMessage)
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.errorRed)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.errorRed.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        
                        // Resend button
                        VStack(spacing: 10) {
                            Text("Didn't receive the code?")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.secondaryText)
                            
                            Button(action: resendCode) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14))
                                    Text(canResend ? "Resend Code" : "Resend in \(resendCountdown)s")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(canResend ? AppTheme.primaryBlue : AppTheme.secondaryText.opacity(0.5))
                            }
                            .disabled(!canResend || authService.isLoading)
                        }
                        .padding(.top, 8)
                        
                        // Verify button
                        Button(action: { Task { await verifyCode() } }) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Verify Code")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(AppTheme.primaryBlue)
                            .foregroundColor(.white)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(otpCode.count != 8 || authService.isLoading)
                        .opacity((otpCode.count != 8 || authService.isLoading) ? 0.6 : 1)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { 
                        // Clear OTP state to go back to login
                        authService.otpSent = false
                        authService.pendingEmail = nil
                        authService.pendingPassword = nil
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(AppTheme.primaryBlue)
                    }
                }
            }
        }
        .onAppear {
            // Delay to ensure view is fully loaded before focusing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isCodeFieldFocused = true
            }
            startCountdown()
        }
    }
    
    private func verifyCode() async {
        let success = await authService.verifyOTP(email: email, code: otpCode)
        if success {
            dismiss()
        }
    }
    
    private func resendCode() {
        guard canResend else { return }
        
        Task {
            // Use the stored password from authService
            guard let password = authService.pendingPassword else {
                authService.errorMessage = "Session expired. Please login again."
                return
            }
            
            let success = await authService.sendOTP(email: email, password: password)
            if success {
                otpCode = ""
                canResend = false
                resendCountdown = 60
                startCountdown()
            }
        }
    }
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if resendCountdown > 0 {
                resendCountdown -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
    
    private func getDigit(at index: Int) -> String {
        guard index < otpCode.count else { return "" }
        let digitIndex = otpCode.index(otpCode.startIndex, offsetBy: index)
        return String(otpCode[digitIndex])
    }
}

// MARK: - OTP Digit Box Component

struct OTPDigitBox: View {
    let digit: String
    let isFocused: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                        .stroke(
                            isFocused ? AppTheme.primaryBlue : AppTheme.secondaryText.opacity(0.2),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .frame(width: 36, height: 48)
                .shadow(
                    color: isFocused ? AppTheme.primaryBlue.opacity(0.2) : Color.black.opacity(0.05),
                    radius: isFocused ? 4 : 2,
                    x: 0,
                    y: 2
                )
            
            Text(digit)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.primaryText)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .scaleEffect(isFocused ? 1.05 : 1.0)
    }
}

#Preview {
    OTPVerificationView(email: "user@example.com")
        .environmentObject(AuthService())
}
