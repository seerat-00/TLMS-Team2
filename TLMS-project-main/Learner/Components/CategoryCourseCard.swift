//
//  CategoryCourseCard.swift
//  TLMS-project-main
//
//  Created by Chehak on 16/01/26.
//

import Foundation
import SwiftUI

struct CategoryCourseCard: View {
    let course: Course
    let isEnrolled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Course Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(course.categoryColor.opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Image(systemName: course.categoryIcon)
                    .font(.system(size: 28))
                    .foregroundColor(course.categoryColor)
            }
            
            // Course Info
            VStack(alignment: .leading, spacing: 6) {
                Text(course.title)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(2)
                
                Text(course.description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    // Category Badge
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 10))
                        Text(course.category)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundColor(course.categoryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(course.categoryColor.opacity(0.15))
                    .cornerRadius(6)
                    .fixedSize()
                    
                    // Module Count
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                        .font(.system(size: 10))
                        Text("\(course.modules.count)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .fixedSize()
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Enrollment Status / Arrow
            if isEnrolled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.successGreen)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
