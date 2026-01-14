//
//  AuthService.swift
//  TLMS-project-main
//
//  Service for handling Supabase authentication
//

import Foundation
import Combine
import Supabase

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var entryPoint: AuthEntryPoint?

    enum AuthEntryPoint {
        case login
        case signup
    }
    
    // 2FA/OTP state
    @Published var pendingEmail: String?
    @Published var pendingPassword: String? // Store password for verification after OTP
    @Published var otpSent = false
    @Published var otpVerified = false
    
    private let supabase: SupabaseClient
    
    init() {
        // Validate configuration
        guard SupabaseConfig.isConfigured else {
            fatalError("""
            SUPABASE NOT CONFIGURED
            
            Please follow these steps:
            1. Create a Supabase project at https://supabase.com
            2. Get your Project URL and Anon Key from Settings → API
            3. Open SupabaseConfig.swift
            4. Replace YOUR_SUPABASE_URL_HERE with your actual URL
            5. Replace YOUR_SUPABASE_ANON_KEY_HERE with your actual key
            
            See SUPABASE_SETUP_STEPS.md for detailed instructions.
            """)
        }
        
        // Use shared client
        self.supabase = SupabaseManager.shared.client
        
        // Check for existing session
        Task {
            await checkSession()
        }

    }
    
    // MARK: - Session Management
    func checkSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let _ = try await supabase.auth.session

            if entryPoint == nil {
                entryPoint = .login
            }

            await fetchUserProfile()
        } catch {
            print("No active session:", error)
            isAuthenticated = false
            currentUser = nil
        }
    }

    // MARK: - Sign Up
    
    func signUp(email: String, password: String, fullName: String, role: UserRole, resumeData: Data? = nil, resumeFileName: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Sign up with Supabase Auth
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: [
                    "full_name": .string(fullName),
                    "role": .string(role.rawValue)
                ]
            )
            
            // Wait a moment for the trigger to create the profile
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Fetch the created user profile with retry
            var retries = 3
            while retries > 0 {
                await fetchUserProfile()
                if currentUser != nil {
                    break
                }
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                retries -= 1
            }
            
            if currentUser == nil {
                errorMessage = "Account created but profile not found. Please try logging in."
                return false
            }
            
            // Upload resume AFTER profile is created (for educators)
            if let resumeData = resumeData, let resumeFileName = resumeFileName, role == .educator {
                if let resumeUrl = await uploadResume(fileData: resumeData, fileName: resumeFileName, userId: response.user.id) {
                    // Update user profile with resume URL
                    do {
                        try await supabase
                            .from("user_profiles")
                            .update(["resume_url": resumeUrl])
                            .eq("id", value: response.user.id.uuidString)
                            .execute()
                        
                        // Refresh user profile to get updated data
                        await fetchUserProfile()
                    } catch {
                        print("Warning: Failed to save resume URL: \(error.localizedDescription)")
                        // Don't fail signup if resume URL update fails
                    }
                }
            }
            self.entryPoint = .signup
            return true
        } catch {
            errorMessage = "Sign up failed: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Resume Upload
    
    func uploadResume(fileData: Data, fileName: String, userId: UUID) async -> String? {
        do {
            let fileExtension = (fileName as NSString).pathExtension
            let sanitizedFileName = "resume.\(fileExtension)"
            let filePath = "\(userId.uuidString)/\(sanitizedFileName)"
            
            // Upload to Supabase Storage
            try await supabase.storage
                .from("educator-resumes")
                .upload(
                    filePath,
                    data: fileData,
                    options: .init(
                        cacheControl: "3600",
                        contentType: mimeType(for: fileExtension),
                        upsert: true
                    )
                )
            
            // Create signed URL (valid for 1 hour) for private bucket
            let url = try await supabase.storage
                .from("educator-resumes")
                .createSignedURL(path: filePath, expiresIn: 3600)
            
            return url.absoluteString
        } catch {
            errorMessage = "Failed to upload resume: \(error.localizedDescription)"
            return nil
        }
    }
    
    private func mimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        default:
            return "application/octet-stream"
        }
    }
    
    
    // MARK: - Email Validation
    
    func isValidEmail(_ email: String) -> Bool {
        // Check basic email format
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            return false
        }
        
        // Check for common email domains
        let commonDomains = ["gmail.com", "yahoo.com", "outlook.com", "hotmail.com", "icloud.com", "protonmail.com"]
        let lowercasedEmail = email.lowercased()
        
        for domain in commonDomains {
            if lowercasedEmail.hasSuffix("@" + domain) {
                return true
            }
        }
        
        errorMessage = "Please use a valid email address (e.g., @gmail.com, @yahoo.com, @outlook.com)"
        return false
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let _ = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Fetch user profile
            await fetchUserProfile()
            self.entryPoint = .login
            return true

        } catch {
            errorMessage = "Login failed: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signOut()
            currentUser = nil
            isAuthenticated = false
            entryPoint = nil
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Two-Factor Authentication (OTP)
    
    func sendOTP(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Validate email format first
        guard isValidEmail(email) else {
            isLoading = false
            return false
        }
        
        do {
            // CRITICAL: Verify password BEFORE sending OTP
            let _ = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Password is correct, now sign out and send OTP for 2FA
            try await supabase.auth.signOut()
            
            // Now send OTP
            try await supabase.auth.signInWithOTP(email: email)
            pendingEmail = email
            pendingPassword = password
            otpSent = true
            return true
        } catch let error as AuthError {
            // Check if it's an invalid credentials error
            if error.localizedDescription.contains("Invalid") || error.localizedDescription.contains("credentials") {
                errorMessage = "Invalid email or password. Please check your credentials."
            } else {
                errorMessage = "Failed to send verification code: \(error.localizedDescription)"
            }
            return false
        } catch {
            errorMessage = "Failed to send verification code: \(error.localizedDescription)"
            return false
        }
    }
    
    func setPendingPassword(_ password: String) {
        pendingPassword = password
    }
    
    func verifyOTP(email: String, code: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Verify the OTP - this logs the user in
            let _ = try await supabase.auth.verifyOTP(
                email: email,
                token: code,
                type: .email
            )
            
            // OTP verified and user is now authenticated
            // Just fetch the user profile
            await fetchUserProfile()
            
            // Clear OTP state
            otpVerified = true
            otpSent = false
            pendingEmail = nil
            pendingPassword = nil
            
            return true
        } catch {
            errorMessage = "Invalid or expired code. Please try again."
            return false
        }
    }
    
    func resetOTPState() {
        otpSent = false
        otpVerified = false
        pendingEmail = nil
        pendingPassword = nil
        errorMessage = nil
    }
    
    // MARK: - Fetch User Profile
    
    private func fetchUserProfile() async {
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id
            
            let response: User = try await supabase
                .from("user_profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            currentUser = response
            isAuthenticated = true
        } catch {
            errorMessage = "Failed to fetch user profile: \(error.localizedDescription)"
            isAuthenticated = false
        }
    }
    
    // MARK: - Admin Functions
    
    func fetchPendingEducators() async -> [User] {
        do {
            let response: [User] = try await supabase
                .from("user_profiles")
                .select()
                .eq("role", value: "educator")
                .eq("approval_status", value: "pending")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            errorMessage = "Failed to fetch pending educators: \(error.localizedDescription)"
            return []
        }
    }
    
    func approveEducator(userId: UUID) async -> Bool {
        do {
            try await supabase.rpc("approve_educator", params: ["educator_id": userId.uuidString]).execute()
            return true
        } catch {
            errorMessage = "Failed to approve educator: \(error.localizedDescription)"
            return false
        }
    }
    
    func rejectEducator(userId: UUID) async -> Bool {
        do {
            try await supabase.rpc("reject_educator", params: ["educator_id": userId.uuidString]).execute()
            return true
        } catch {
            errorMessage = "Failed to reject educator: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Fetch All Users (Admin)
    
    func fetchAllUsers() async -> [User] {
        do {
            let response: [User] = try await supabase
                .from("user_profiles")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            errorMessage = "Failed to fetch users: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Password Management
    
    func updatePassword(newPassword: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Update password in Supabase Auth
            let _ = try await supabase.auth.update(
                user: UserAttributes(password: newPassword)
            )
            
            // If current user is admin, update the password_reset_required flag
            if let user = currentUser, user.role == .admin {
                try await supabase
                    .from("user_profiles")
                    .update(["password_reset_required": false])
                    .eq("id", value: user.id.uuidString)
                    .execute()
                
                // Refresh profile
                await fetchUserProfile()
            }
            
            return true
        } catch {
            errorMessage = "Failed to update password: \(error.localizedDescription)"
            return false
        }
    }
}
