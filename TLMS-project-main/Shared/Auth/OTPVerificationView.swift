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
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.25, blue: 0.5),
                    Color(red: 0.25, green: 0.15, blue: 0.4),
                    Color(red: 0.2, green: 0.2, blue: 0.45)
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    animateGradient = true
                }
                startCountdown()
            }
            
            VStack(spacing: 30) {
                Spacer()
                
                // Icon
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .white.opacity(0.3), radius: 20)
                
                // Title
                VStack(spacing: 12) {
                    Text("Enter Verification Code")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("We sent an 8-digit code to")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(email)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
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
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Error message
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Resend button
                VStack(spacing: 12) {
                    Text("Didn't receive the code?")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Button(action: resendCode) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text(canResend ? "Resend Code" : "Resend in \(resendCountdown)s")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(canResend ? .white : .white.opacity(0.5))
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
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.5, green: 0.3, blue: 0.9),
                                Color(red: 0.4, green: 0.5, blue: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color(red: 0.5, green: 0.3, blue: 0.9).opacity(0.5), radius: 15, y: 8)
                }
                .disabled(otpCode.count != 8 || authService.isLoading)
                .opacity((otpCode.count != 8 || authService.isLoading) ? 0.6 : 1)
                .padding(.horizontal, 30)
                
                // Back button
                Button(action: { dismiss() }) {
                    Text("Use different email")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
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
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused ? Color.blue.opacity(0.8) : Color.white.opacity(0.3),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .frame(width: 42, height: 56)
            
            Text(digit)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    OTPVerificationView(email: "user@example.com")
        .environmentObject(AuthService())
}
