//
//  AdminCourseValueView.swift
//  TLMS-project-main
//
//  Screen for admins to monitor course value (ratings vs price)
//

import SwiftUI

struct AdminCourseValueView: View {
    @StateObject private var viewModel = AdminCourseValueViewModel()
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
                        .background(AppTheme.secondaryBlue)
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
        .task {
            await viewModel.loadCourses()
        }
    }
}


struct CourseValueRow: View {
    let course: Course
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail / Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.primaryBlue.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                if let url = course.courseCoverUrl, let _ = URL(string: url) {
                    // Ideally use AsyncImage, simplified here with icon fallback
                    AsyncImage(url: URL(string: url)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "book.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(10)
                    .clipped()
                } else {
                    Image(systemName: "book.fill")
                        .font(.title2)
                        .foregroundColor(AppTheme.primaryBlue)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(course.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    // Rating
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(String(format: "%.1f", course.rating ?? 0.0))
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Students
                    HStack(spacing: 2) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.primaryBlue)
                        Text("\(course.enrolledCount ?? 0)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Price
                    HStack(spacing: 2) {
                        Text(course.price == 0 ? "Free" : "$\(String(format: "%.2f", course.price ?? 0.0))")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.successGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.successGreen.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    AdminCourseValueView()
}
