//
//  AdminCourseValueView.swift
//  TLMS-project-main
//
//  Screen for admins to monitor course value (ratings vs price)
//

import SwiftUI

struct AdminCourseValueView: View {
    @ObservedObject var viewModel: AdminCourseValueViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showDeleteAlert = false
    @State private var courseToRemove: Course?
    @State private var removalReason = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Sort Control
            VStack(spacing: 12) {
                HStack {
                    Text("Course Value Monitor")
                        .font(.title2.bold())
                    Spacer()
                }
                .padding(.horizontal)
                
                // Sort Picker - Segmented or Menu
                // Using a Menu for cleaner look if many options, or horizontal scroll
                HStack {
                    Text("Sort by:")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    Menu {
                        ForEach(AdminCourseSortOption.allCases) { option in
                            Button {
                                viewModel.sortOption = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if viewModel.sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.sortOption.rawValue)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.secondaryBackground)
                        .cornerRadius(8)
                        .foregroundColor(AppTheme.primaryBlue)
                    }
                    
                    Spacer()
                    
                    Text("\(viewModel.courses.count) Courses")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(AppTheme.background)
            
            Divider()
            
            // Content
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Spacer()
            } else if viewModel.courses.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.secondaryText)
                    Text("No published courses found")
                        .font(.headline)
                        .foregroundColor(AppTheme.secondaryText)
                }
                Spacer()
            } else {
                List {
                    ForEach(viewModel.courses) { course in
                        CourseValueRow(course: course)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .contextMenu {
                                Button(role: .destructive) {
                                    courseToRemove = course
                                    removalReason = ""
                                    showDeleteAlert = true
                                } label: {
                                    Label("Remove Course", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    courseToRemove = course
                                    removalReason = ""
                                    showDeleteAlert = true
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .background(AppTheme.groupedBackground)
                .refreshable {
                    await viewModel.loadCourses()
                }
                .alert("Remove Course", isPresented: $showDeleteAlert, presenting: courseToRemove) { course in
                    TextField("Reason for removal", text: $removalReason)
                    Button("Remove", role: .destructive) {
                        if !removalReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Task {
                                await viewModel.removeCourse(course, reason: removalReason)
                            }
                        } else {
                           // Ideally keep alert open or show error, but standard alert dismisses on button tap.
                           // For now, fail silently (action won't trigger) - standard behavior for basic Input Alerts
                           // Or better: Re-trigger alert? No, that's bad UX.
                           // User should see the button disabled but SwiftUI Alert buttons don't support .disabled easily in all versions.
                           // I will stick to: If empty, nothing happens (course not removed).
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        courseToRemove = nil
                        removalReason = ""
                    }
                } message: { course in
                    Text("Enter the reason for removing '\(course.title)'. This will be sent to the educator.")
                }
            }
        }
        .background(AppTheme.groupedBackground)
    }
}


struct CourseValueRow: View {
    let course: Course
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Image Header
            ZStack(alignment: .topLeading) {
                // Course Image
                let imageName = CourseImageHelper.getCourseImage(courseCoverUrl: course.courseCoverUrl, category: course.category)
                
                if let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [categoryColor.opacity(0.6), categoryColor.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: categoryIcon)
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundColor(.white.opacity(0.3))
                    )
                    .frame(height: 150)
                }
                
                // Gradient Overlay
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.6)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 150)
                
                // Price Tag (Top Right)
                VStack {
                    HStack {
                        Spacer()
                        Text(course.price == 0 ? "Free" : (course.price ?? 0.0).formatted(.currency(code: "INR")))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(course.price == 0 ? AppTheme.successGreen : .white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                changePriceBackground(price: course.price)
                            )
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }
                    Spacer()
                }
                .padding(12)
                
                // Title (Bottom Left)
                VStack {
                    Spacer()
                    Text(course.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .padding(16)
                }
            }
            .frame(height: 150)
            .background(Color.black)
            
            // MARK: - Content Section
            VStack(alignment: .leading, spacing: 12) {
                
                // Metadata Row
                HStack(spacing: 12) {
                    // Category
                    Label(course.category, systemImage: "folder.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(categoryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(categoryColor.opacity(0.1))
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    // Rating
                    if let rating = course.ratingAvg, rating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", rating))
                                .font(.caption.weight(.bold))
                                .foregroundColor(.primary)
                        }
                    } else {
                        Text("No ratings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Stats Row
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(AppTheme.primaryBlue)
                        Text("\(course.enrolledCount ?? 0) Enrolled")
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "book.fill")
                            .foregroundColor(AppTheme.primaryBlue)
                        Text("\(course.modules.count) Modules")
                    }
                    
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(16)
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // Helper to style price tag
    private func changePriceBackground(price: Double?) -> Color {
        if price == 0 {
            return Color.white
        } else {
            return AppTheme.primaryBlue
        }
    }
}

#Preview {
    AdminCourseValueView(viewModel: AdminCourseValueViewModel())
}
