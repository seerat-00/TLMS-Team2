//
//  StorageService.swift
//  TLMS-project-main
//
//  Service for uploading files to Supabase Storage
//

import Foundation
import Combine
import Supabase

@MainActor
class StorageService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared.client
    private let bucketName = "lesson-content"
    
    /// Upload a file to Supabase Storage and return the public URL
    func uploadFile(
        fileURL: URL,
        fileName: String,
        contentType: String? = nil
    ) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        
        defer {
            isUploading = false
            uploadProgress = 0.0
        }
        
        do {
            // 1. Read file data
            let fileData = try Data(contentsOf: fileURL)
            
            // 2. Generate unique file name to avoid collisions
            let timestamp = Int(Date().timeIntervalSince1970)
            let fileExtension = fileURL.pathExtension
            let uniqueFileName = "\(timestamp)_\(fileName.replacingOccurrences(of: " ", with: "_")).\(fileExtension)"
            
            // 3. Determine content type
            let mimeType = contentType ?? getMimeType(for: fileExtension)
            
            uploadProgress = 0.3
            
            // 4. Upload to Supabase Storage
            _ = try await supabase.storage
                .from(bucketName)
                .upload(
                    path: uniqueFileName,
                    file: fileData,
                    options: FileOptions(
                        contentType: mimeType,
                        upsert: false
                    )
                )
            
            uploadProgress = 0.8
            
            // 5. Get public URL using the unique file name
            let publicURL = try supabase.storage
                .from(bucketName)
                .getPublicURL(path: uniqueFileName)
            
            uploadProgress = 1.0
            
            print("✅ File uploaded successfully: \(publicURL.absoluteString)")
            return publicURL.absoluteString
            
        } catch {
            errorMessage = "Upload failed: \(error.localizedDescription)"
            print("❌ File upload error: \(error)")
            throw error
        }
    }
    
    /// Delete a file from Supabase Storage using its public URL
    func deleteFile(publicURL: String) async throws {
        // Extract the file path from the public URL
        guard let url = URL(string: publicURL),
              let pathComponents = url.pathComponents.suffix(from: url.pathComponents.count - 1).first else {
            throw StorageError.invalidURL
        }
        
        do {
            try await supabase.storage
                .from(bucketName)
                .remove(paths: [pathComponents])
            
            print("✅ File deleted successfully")
        } catch {
            print("❌ File deletion error: \(error)")
            throw error
        }
    }
    
    /// Get MIME type based on file extension
    private func getMimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        // Videos
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "avi":
            return "video/x-msvideo"
        case "mkv":
            return "video/x-matroska"
        
        // Documents
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        
        // Presentations
        case "ppt":
            return "application/vnd.ms-powerpoint"
        case "pptx":
            return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case "key":
            return "application/x-iwork-keynote-sffkey"
        
        // Images
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        
        default:
            return "application/octet-stream"
        }
    }
}

enum StorageError: Error, LocalizedError {
    case invalidURL
    case uploadFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid file URL"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        }
    }
}
