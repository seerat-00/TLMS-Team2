//
//  PublishedCourseCard.swift
//  TLMS-project-main
//
//  Created by Chehak on 16/01/26.
//

import Foundation
import SwiftUI

struct PublishedCourseCard: View {
    let course: Course
    let isEnrolled: Bool
    var onEnroll: () async -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isEnrolling = false
    
    // Fallbacks for category styling if Course doesn't provide color/icon
    private var categoryColor: Color {
        switch course.category.lowercased() {
        case "design": return .purple
        case "development", "programming", "code": return .blue
        case "marketing": return .orange
        case "business": return .teal
        case "data", "analytics": return .green
        case "photography": return .pink
        case "music": return .indigo
        default: return .gray
        }
    }
    
    private var categoryIcon: String {
        switch course.category.lowercased() {
        case "design": return "pencil.and.outline"
        case "development", "programming", "code": return "chevron.left.forwardslash.chevron.right"
        case "marketing": return "megaphone.fill"
        case "business": return "briefcase.fill"
        case "data", "analytics": return "chart.bar.fill"
        case "photography": return "camera.fill"
        case "music": return "music.note"
        default: return "book.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Course Icon
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 24))
                    .foregroundColor(categoryColor)
            }
            
            // Course Info
            VStack(alignment: .leading, spacing: 6) {
                Text(course.title)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(course.description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 10))
                        Text(course.category)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundColor(categoryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.15))
                    .cornerRadius(6)
                    .fixedSize()
                    
                    // Module Count
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 10))
                        Text("\(course.modules.count)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(AppTheme.secondaryText)
                    .fixedSize()
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Action Button
            if isEnrolled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.successGreen)
            } else {
                Button(action: {
                    Task {
                        isEnrolling = true
                        await onEnroll()
                        isEnrolling = false
                    }
                }) {
                    if isEnrolling {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Enroll")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.primaryBlue)
                            .cornerRadius(20)
                    }
                }
                .disabled(isEnrolling)
            }
        }
        .padding(16)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
