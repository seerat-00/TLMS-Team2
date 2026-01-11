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
