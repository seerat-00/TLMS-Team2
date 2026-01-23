//
//  EducatorCourseCard.swift
//  TLMS-project-main
//
//  Created by Antigravity on 26/01/26.
//

import SwiftUI

struct EducatorCourseCard: View {
    let course: Course
    var onDelete: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onUnpublish: (() -> Void)? = nil
    var onPreview: (() -> Void)? = nil
    var showPreviewIcon: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Category Styling
    
    private var categoryColor: Color {
        switch course.category.lowercased() {
        case "design": return AppTheme.accentPurple
        case "development", "programming", "code": return AppTheme.primaryBlue
        case "marketing": return AppTheme.warningOrange
        case "business": return AppTheme.accentTeal
        case "data", "analytics": return AppTheme.successGreen
        case "photography": return .pink
        case "music": return .indigo
        default: return AppTheme.secondaryText
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
    
    // MARK: - View
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Image Header with Gradient Overlay
            ZStack(alignment: .topLeading) {
                // Course Image
                let imageName = CourseImageHelper.getCourseImage(courseCoverUrl: course.courseCoverUrl, category: course.category)
                
                if let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipped()
                } else {
                    // Fallback gradient
                    LinearGradient(
                        colors: [categoryColor.opacity(0.6), categoryColor.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: categoryIcon)
                            .font(.system(size: 50, weight: .semibold))
                            .foregroundColor(.white.opacity(0.3))
                    )
                    .frame(height: 160)
                }
                
                // Gradient Overlay
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 160)
                
                // Status Badge (top-left)
                HStack(spacing: 4) {
                    Image(systemName: course.status.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(course.status.displayName.uppercased())
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(course.status.color)
                .cornerRadius(6)
                .padding(12)
                
                // Course Title on Image (bottom)
                VStack {
                    Spacer()
                    Text(course.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .frame(height: 160)
            }
            .cornerRadius(16, corners: [.topLeft, .topRight])
            
            // MARK: - Content Section
            VStack(alignment: .leading, spacing: 12) {
                // Rating Row
                HStack {
                    if let rating = course.ratingAvg, rating > 0 {
                        StarRatingDisplayView(
                            rating: rating,
                            size: 14,
                            ratingCount: course.ratingCount
                        )
                    } else {
                        Text("No ratings yet")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Enrollment Count
                    Label("\(course.enrollmentCount)", systemImage: "person.2.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                // Description
                Text(course.description)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(2)
                
                // Metadata Row
                HStack(spacing: 12) {
                    Label(course.category, systemImage: "folder.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(categoryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(categoryColor.opacity(0.12))
                        .cornerRadius(6)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 11))
                        Text("\(course.modules.count) modules")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppTheme.secondaryText)
                }
            }
            .padding(16)
            
            // MARK: - Footer Section (Actions)
            HStack(spacing: 12) {
                if showPreviewIcon {
                    Label("Preview", systemImage: "eye.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryBlue)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if let onEdit = onEdit {
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppTheme.primaryBlue.opacity(0.1))
                                .foregroundColor(AppTheme.primaryBlue)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if let onUnpublish = onUnpublish {
                        Button(action: onUnpublish) {
                            Label("Unpublish", systemImage: "arrow.uturn.down")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if let onDelete = onDelete {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(8)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(
                AppTheme.secondaryGroupedBackground.opacity(0.3)
            )
            .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.15),
                radius: 12,
                x: 0,
                y: 6)
    }
}
