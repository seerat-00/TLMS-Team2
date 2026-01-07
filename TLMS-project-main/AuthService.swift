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
    
    private let supabase: SupabaseClient
    
    init() {
        // Validate configuration
        guard SupabaseConfig.isConfigured else {
            fatalError("""
            ⚠️ SUPABASE NOT CONFIGURED ⚠️
            
            Please follow these steps:
            1. Create a Supabase project at https://supabase.com
            2. Get your Project URL and Anon Key from Settings → API
            3. Open SupabaseConfig.swift
            4. Replace YOUR_SUPABASE_URL_HERE with your actual URL
            5. Replace YOUR_SUPABASE_ANON_KEY_HERE with your actual key
            
            See SUPABASE_SETUP_STEPS.md for detailed instructions.
            """)
        }
        
        guard let url = URL(string: SupabaseConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL: \(SupabaseConfig.supabaseURL)")
        }
        
        self.supabase = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        
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
            let session = try await supabase.auth.session
            if session.user != nil {
                await fetchUserProfile()
            }
        } catch {
            print("No active session: \(error.localizedDescription)")
            isAuthenticated = false
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
            
            // Get public URL
            let url = try supabase.storage
                .from("educator-resumes")
                .getPublicURL(path: filePath)
            
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
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Fetch user profile
            await fetchUserProfile()
            
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
}
