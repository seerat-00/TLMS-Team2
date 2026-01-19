//
//  ContentUploadService.swift
//  TLMS-project-main
//
//  Service for uploading course content files (videos, PDFs, presentations)
//

import Foundation
import Supabase
import Combine

@MainActor
class ContentUploadService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared.client
    
    /// Upload a file to Supabase Storage and return the public URL
    func uploadFile(
        data: Data,
        fileName: String,
        contentType: ContentType,
        courseId: UUID,
        lessonId: UUID
    ) async -> String? {
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        defer { isUploading = false }
        
        do {
            // Determine bucket based on content type
            let bucket = bucketName(for: contentType)
            
            // Create organized path: courseId/lessonId/filename
            let fileExtension = (fileName as NSString).pathExtension
            let sanitizedFileName = "\(lessonId.uuidString).\(fileExtension)"
            let filePath = "\(courseId.uuidString)/\(sanitizedFileName)"
            
            print("📤 Uploading to: \(bucket)/\(filePath)")
            
            // Upload to Supabase Storage
            try await supabase.storage
                .from(bucket)
                .upload(
                    filePath,
                    data: data,
                    options: .init(
                        cacheControl: "3600",
                        contentType: mimeType(for: fileExtension),
                        upsert: true
                    )
                )
            
            uploadProgress = 1.0
            
            // Get public URL
            let publicURL = try supabase.storage
                .from(bucket)
                .getPublicURL(path: filePath)
            
            print("✅ Upload successful: \(publicURL.absoluteString)")
            return publicURL.absoluteString
            
        } catch {
            print("❌ Upload failed: \(error)")
            errorMessage = "Failed to upload \(contentType.rawValue): \(error.localizedDescription)"
            return nil
        }
    }
    
    /// Delete a file from Supabase Storage
    func deleteFile(fileURL: String, contentType: ContentType) async -> Bool {
        do {
            let bucket = bucketName(for: contentType)
            
            // Extract path from URL
            guard let url = URL(string: fileURL),
                  let pathComponents = url.pathComponents.dropFirst(4).joined(separator: "/").removingPercentEncoding else {
                print("❌ Invalid URL format: \(fileURL)")
                return false
            }
            
            try await supabase.storage
                .from(bucket)
                .remove(paths: [pathComponents])
            
            print("🗑️ Deleted file: \(pathComponents)")
            return true
        } catch {
            print("❌ Delete failed: \(error)")
            errorMessage = "Failed to delete file: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func bucketName(for contentType: ContentType) -> String {
        switch contentType {
        case .video:
            return "course-videos"
        case .pdf:
            return "course-pdfs"
        case .presentation:
            return "course-presentations"
        case .text, .quiz:
            return "course-files" // Fallback, though text/quiz don't use files
        }
    }
    
    private func mimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "pdf":
            return "application/pdf"
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "avi":
            return "video/x-msvideo"
        case "ppt", "pptx":
            return "application/vnd.ms-powerpoint"
        case "key":
            return "application/x-iwork-keynote-sffkey"
        case "txt":
            return "text/plain"
        case "doc", "docx":
            return "application/msword"
        default:
            return "application/octet-stream"
        }
    }
}
