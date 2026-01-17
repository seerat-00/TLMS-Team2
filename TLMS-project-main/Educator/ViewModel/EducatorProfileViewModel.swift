//
//  EducatorProfileViewModel.swift
//  TLMS-project-main
//
//  ViewModel for Educator Profile logic
//

import SwiftUI
import Supabase
import Combine
import PhotosUI

@MainActor
class EducatorProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var profileImageURL: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSaving = false
    @Published var saveMessage: String?
    
    // Auth actions state
    @Published var showChangePassword = false
    @Published var resetEmailSent = false
    
    // Upload state
    @Published var isUploadingResume = false
    @Published var isUploadingImage = false
    
    private let supabase = SupabaseManager.shared.client
    
    // MARK: - Initialization
    
    init(user: User?) {
        self.user = user
        Task {
            await fetchExtendedProfileData()
        }
    }
    
    // MARK: - Data Fetching
    
    func loadProfileData() async {
        isLoading = true
        defer { isLoading = false }
        
        await fetchLatestUser()
        await fetchExtendedProfileData()
    }
    
    func fetchLatestUser() async {
        guard let currentUserId = user?.id else { return }
        
        do {
            let fetchedUser: User = try await supabase
                .from("user_profiles")
                .select()
                .eq("id", value: currentUserId.uuidString)
                .single()
                .execute()
                .value
            
            self.user = fetchedUser
            // Also update resume URL from user object if available there
            // (Standard User struct has resumeUrl)
        } catch {
            print("Error fetching user: \(error)")
        }
    }
    
    // Fetch extra fields like profile_image_url that might not be in the shared User struct
    func fetchExtendedProfileData() async {
        guard let currentUserId = user?.id else { return }
        
        struct ExtendedProfile: Decodable {
            let profile_image_url: String?
        }
        
        do {
            let response: ExtendedProfile = try await supabase
                .from("user_profiles")
                .select("profile_image_url")
                .eq("id", value: currentUserId.uuidString)
                .single()
                .execute()
                .value
            
            self.profileImageURL = response.profile_image_url
        } catch {
            // Field might not exist or other error, just ignore
            print("Extended profile fetch error (might be expected if column missing): \(error)")
        }
    }
    
    // MARK: - Profile Management
    
    func updateProfile(fullName: String) async {
        guard let userId = user?.id else { return }
        guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Name cannot be empty"
            return
        }
        
        isSaving = true
        errorMessage = nil
        saveMessage = nil
        defer { isSaving = false }
        
        do {
            try await supabase
                .from("user_profiles")
                .update(["full_name": fullName])
                .eq("id", value: userId.uuidString)
                .execute()
            
            await fetchLatestUser()
            saveMessage = "Profile updated successfully"
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Uploads
    
    func uploadResume(data: Data, fileName: String) async {
        guard let userId = user?.id else { return }
        
        isUploadingResume = true
        errorMessage = nil
        defer { isUploadingResume = false }
        
        do {
            let fileExtension = (fileName as NSString).pathExtension
            
            // Reuse logic similar to AuthService but implemented here to avoid modyfing Shared Service if not exposed
            // AuthService HAS uploadResume, but it returns URL and doesn't update profile automatically in all cases or might be private/internal behavior we want to control.
            // Actually AuthService.uploadResume IS exposed. Let's try to use it if we can access the instance, 
            // but for cleaner separation and specific Educator flow, implementing locally is safe.
            
            let sanitizedFileName = "resume.\(fileExtension)"
            let filePath = "\(userId.uuidString)/\(sanitizedFileName)"
            
            // Upload
            try await supabase.storage
                .from("educator-resumes")
                .upload(
                    filePath,
                    data: data,
                    options: .init(
                        cacheControl: "3600",
                        contentType: mimeType(for: fileExtension),
                        upsert: true
                    )
                )
            
            // Get URL
            let signedURL = try await supabase.storage
                .from("educator-resumes") // Private bucket usually needs signed URL
                .createSignedURL(path: filePath, expiresIn: 3600 * 24 * 365) // Long expiry or use public URL if bucket is public. Assuming signed for now.
            
            // Update profile
            try await supabase
                .from("user_profiles")
                .update(["resume_url": signedURL.absoluteString])
                .eq("id", value: userId.uuidString)
                .execute()
            
            await fetchLatestUser()
            saveMessage = "Resume uploaded successfully"
            
        } catch {
            errorMessage = "Failed to upload resume: \(error.localizedDescription)"
        }
    }
    
    func uploadProfilePicture(item: PhotosPickerItem) async {
        guard let userId = user?.id else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        
        isUploadingImage = true
        errorMessage = nil
        defer { isUploadingImage = false }
        
        do {
            let filePath = "\(userId.uuidString)/avatar.jpg"
            
            // compress/resize logic could go here, skipping for simple implementation
            
            do {
                try await supabase.storage
                    .from("avatars")
                    .upload(
                        filePath,
                        data: data,
                        options: FileOptions(
                            cacheControl: "3600",
                            contentType: "image/jpeg",
                            upsert: true
                        )
                    )
            } catch {
                // Known issue: Success 200 OK might return empty body causing parsing error
                let errorString = String(describing: error)
                if errorString.contains("cannot parse response") || error.localizedDescription.contains("cannot parse response") {
                    print("Warning: Ignoring parsing error for upload (likely success): \(error)")
                } else {
                    // Real error, rethrow
                    throw error
                }
            }
            
            // Get Public URL (Avatars usually public)
            let publicURL = try supabase.storage
                .from("avatars")
                .getPublicURL(path: filePath)
            
            // Append timestamp to bust cache
            let finalURL = publicURL.absoluteString + "?t=\(Date().timeIntervalSince1970)"
            
            // Update local state immediately so UI reflects change
            self.profileImageURL = finalURL
            saveMessage = "Profile picture updated"
            
            // Try to update profile in DB
            do {
                struct UpdateProfileImage: Encodable {
                    let profile_image_url: String?
                }
                
                try await supabase
                    .from("user_profiles")
                    .update(UpdateProfileImage(profile_image_url: finalURL))
                    .eq("id", value: userId.uuidString)
                    .execute()
            } catch {
                print("Warning: Failed to save profile_image_url to DB: \(error)")
            }
            
        } catch {
            print("Upload error details: \(error)")
            errorMessage = "Failed to upload profile picture: \(error.localizedDescription)"
        }
    }
    
    func removeProfilePicture() async {
        guard let userId = user?.id else { return }
        
        isUploadingImage = true
        errorMessage = nil
        defer { isUploadingImage = false }
        
        do {
            // 1. Remove from Storage (Optional, but keeps bucket clean)
            let filePath = "\(userId.uuidString)/avatar.jpg"
            try? await supabase.storage
                .from("avatars")
                .remove(paths: [filePath])
            
            // 2. Update DB to null
            struct UpdateProfileImage: Encodable {
                let profile_image_url: String?
            }
            
            try await supabase
                .from("user_profiles")
                .update(UpdateProfileImage(profile_image_url: nil))
                .eq("id", value: userId.uuidString)
                .execute()
            
            self.profileImageURL = nil
            saveMessage = "Profile picture removed"
        } catch {
            errorMessage = "Failed to remove profile picture: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Auth Actions
    
    func sendPasswordResetEmail() async {
        guard let email = user?.email else { return }
        
        isLoading = true
        errorMessage = nil
        resetEmailSent = false
        defer { isLoading = false }
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            resetEmailSent = true
        } catch {
            errorMessage = "Failed to send reset email: \(error.localizedDescription)"
        }
    }
    
    // Helper
    private func mimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "pdf": return "application/pdf"
        case "doc": return "application/msword"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        default: return "application/octet-stream"
        }
    }
}
