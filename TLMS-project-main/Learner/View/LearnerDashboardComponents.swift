//
//  SortOptionButton.swift
//  TLMS-project-main
//
//  Created by Chehak on 16/01/26.
//

import Foundation
import SwiftUI

// MARK: - Sort Option Button

struct SortOptionButton: View {
    let option: CourseSortOption
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: option.icon)
                    .font(.system(size: 14, weight: .semibold))

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.displayName)
                        .font(.system(size: 14, weight: .semibold))

                    Text(option.description)
                        .font(.system(size: 11))
                        .opacity(0.8)
                }
            }
            .foregroundColor(isSelected ? .white : AppTheme.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.primaryBlue : AppTheme.secondaryGroupedBackground)
                    .shadow(
                        color: isSelected ? AppTheme.primaryBlue.opacity(0.3) : Color.black.opacity(0.05),
                        radius: isSelected ? 8 : 2,
                        x: 0,
                        y: isSelected ? 4 : 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? AppTheme.primaryBlue : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

//
// MARK: - Category Chip
//

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ?
                AppTheme.primaryBlue :
                    Color.clear
            )
            .foregroundColor(
                isSelected ?
                    .white :
                    AppTheme.primaryBlue
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppTheme.primaryBlue, lineWidth: isSelected ? 0 : 1.5)
            )
        }
        .shadow(
            color: isSelected ? AppTheme.primaryBlue.opacity(0.3) : Color.clear,
            radius: isSelected ? 8 : 0,
            x: 0,
            y: 2
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

//
// MARK: - Category Courses View
//

struct CategoryCoursesView: View {
    let category: String
    let courses: [Course]
    let userId: UUID
    @Environment(\.dismiss) var dismiss
    @StateObject private var courseService = CourseService()
    @State private var enrolledCourseIds: Set<UUID> = []
    @State private var searchText = ""

    var filteredCourses: [Course] {
        if searchText.isEmpty {
            return courses
        }
        return courses.filter { course in
            course.title.localizedCaseInsensitiveContains(searchText) ||
            course.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            AppTheme.groupedBackground
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search in \(category)", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(AppTheme.secondaryGroupedBackground)
                .cornerRadius(12)
                .padding()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        if filteredCourses.isEmpty {
                            LearnerEmptyState(
                                icon: "book.closed.fill",
                                title: "No Courses Found",
                                message: searchText.isEmpty ? "Check back later for \(category) courses" : "No courses match your search"
                            )
                            .padding(.top, 60)
                        } else {
                            ForEach(filteredCourses) { course in
                                NavigationLink(
                                    destination:
                                        LearnerCourseDetailView(
                                            course: course,
                                            isEnrolled: enrolledCourseIds.contains(course.id),
                                            userId: userId,
                                            onEnroll: {}
                                        )
                                ) {
                                    CategoryCourseCard(
                                        course: course,
                                        isEnrolled: enrolledCourseIds.contains(course.id)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.large)
    }
}
