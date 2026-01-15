//
//  SupabaseManager.swift
//  TLMS-project-main
//
//  Shared Supabase client instance to ensure session consistency
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        guard let url = URL(string: SupabaseConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL: \(SupabaseConfig.supabaseURL)")
        }
        
        // Use default configuration which handles session persistence automatically
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
    }
    
    // MARK: - Course Content Storage
    
    func uploadLessonContent(
        fileData: Data,
        fileName: String,
        educatorID: UUID,
        courseID: UUID,
        moduleID: UUID,
        lessonID: UUID,
        contentType: ContentType
    ) async throws -> String {
        let fileExtension = (fileName as NSString).pathExtension
        let sanitizedFileName = "\(lessonID.uuidString).\(fileExtension)"
        let filePath = "\(educatorID.uuidString)/\(courseID.uuidString)/\(moduleID.uuidString)/\(sanitizedFileName)"
        
        let mimeType = self.mimeType(for: fileExtension, contentType: contentType)
        
        try await client.storage
            .from("course-materials")
            .upload(
                filePath,
                data: fileData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: mimeType,
                    upsert: true
                )
            )
        
        let publicURL = try client.storage
            .from("course-materials")
            .getPublicURL(path: filePath)
        
        return publicURL.absoluteString
    }
    
    func deleteLessonContent(fileUrl: String) async throws {
        guard let url = URL(string: fileUrl),
              let bucketIndex = url.pathComponents.firstIndex(of: "course-materials"),
              bucketIndex < url.pathComponents.count - 1 else {
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid file URL"])
        }
        
        let pathComponents = url.pathComponents[(bucketIndex + 1)...]
        let filePath = pathComponents.joined(separator: "/")
        
        try await client.storage
            .from("course-materials")
            .remove(paths: [filePath])
    }
    
    private func mimeType(for fileExtension: String, contentType: ContentType) -> String {
        let ext = fileExtension.lowercased()
        
        switch contentType {
        case .video:
            switch ext {
            case "mp4": return "video/mp4"
            case "mov": return "video/quicktime"
            case "m4v": return "video/x-m4v"
            default: return "video/mp4"
            }
        case .pdf:
            return "application/pdf"
        case .presentation:
            switch ext {
            case "key": return "application/vnd.apple.keynote"
            case "ppt": return "application/vnd.ms-powerpoint"
            case "pptx": return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            default: return "application/vnd.apple.keynote"
            }
        default:
            return "application/octet-stream"
        }
    }
}
