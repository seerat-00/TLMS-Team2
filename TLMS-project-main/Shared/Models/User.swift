//
//  User.swift
//  TLMS-project-main
//
//  User model for authentication system
//

import Foundation

enum UserRole: String, Codable, CaseIterable {
    case learner = "learner"
    case educator = "educator"
    case admin = "admin"
    
    var displayName: String {
        switch self {
        case .learner: return "Learner"
        case .educator: return "Educator"
        case .admin: return "Admin"
        }
    }
}

enum ApprovalStatus: String, Codable {
    case approved = "approved"
    case pending = "pending"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .approved: return "Approved"
        case .pending: return "Pending Approval"
        case .rejected: return "Rejected"
        }
    }
}

struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    let fullName: String
    let role: UserRole
    let approvalStatus: ApprovalStatus
    let resumeUrl: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case role
        case approvalStatus = "approval_status"
        case resumeUrl = "resume_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Check if user can access their role-specific features
    var canAccessFeatures: Bool {
        switch role {
        case .learner, .admin:
            return approvalStatus == .approved
        case .educator:
            return approvalStatus == .approved
        }
    }
    
    // Display status message
    var statusMessage: String? {
        if role == .educator && approvalStatus == .pending {
            return "Your educator account is pending admin approval. You'll be notified once approved."
        } else if approvalStatus == .rejected {
            return "Your account has been rejected. Please contact support for more information."
        }
        return nil
    }
}
