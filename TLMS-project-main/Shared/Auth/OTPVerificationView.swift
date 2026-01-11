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
    @State private var animateGradient = false
    @State private var resendCountdown = 60
    @State private var canResend = false
    @FocusState private var isCodeFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.groupedBackground
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Icon
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 70))
                    .foregroundStyle(AppTheme.primaryBlue)
                    .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 20)
                
                // Title
                VStack(spacing: 12) {
                    Text("Enter Verification Code")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text("We sent an 8-digit code to")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.secondaryText)
                    
                    Text(email)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                }
                
                
                // OTP Input - 6 individual boxes
                VStack(spacing: 20) {
                    HStack(spacing: 10) {
                        ForEach(0..<8, id: \.self) { index in
                            OTPDigitBox(
                                digit: getDigit(at: index),
                                isFocused: otpCode.count == index
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
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
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.secondaryText.opacity(0.6))
                }
                
                // Error message
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.errorRed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Resend button
                VStack(spacing: 12) {
                    Text("Didn't receive the code?")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.secondaryText)
                    
                    Button(action: resendCode) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text(canResend ? "Resend Code" : "Resend in \(resendCountdown)s")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(canResend ? AppTheme.primaryBlue : AppTheme.secondaryText.opacity(0.5))
                    }
                    .disabled(!canResend || authService.isLoading)
                }
                
                // Verify button
                Button(action: { Task { await verifyCode() } }) {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Verify Code")
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
                .disabled(otpCode.count != 8 || authService.isLoading)
                .opacity((otpCode.count != 8 || authService.isLoading) ? 0.6 : 1)
                .padding(.horizontal, 30)
                
                // Back button
                Button(action: { dismiss() }) {
                    Text("Use different email")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            isCodeFieldFocused = true
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
            let success = await authService.sendOTP(email: email)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.secondaryGroupedBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused ? AppTheme.primaryBlue : AppTheme.secondaryText.opacity(0.3),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .frame(width: 42, height: 56)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            Text(digit)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(AppTheme.primaryText)
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    OTPVerificationView(email: "user@example.com")
        .environmentObject(AuthService())
}
