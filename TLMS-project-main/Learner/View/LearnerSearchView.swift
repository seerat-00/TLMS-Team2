//
//  LearnerSearchView.swift
//  TLMS-project-main
//
//  Created by Chehak on 16/01/26.
//

import SwiftUI

struct LearnerSearchView: View {
    let user: User
    @Binding var selectedCategory: String?
    @Binding var searchText: String

    let isEnrolled: (Course) -> Bool
    let enroll: (Course) async -> Void
    let handleLogout: () -> Void
    let browseOnlyCourses: [Course]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.groupedBackground
                    .ignoresSafeArea(edges: .top)

                if selectedCategory == nil {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ],
                            spacing: 16
                        ) {
                            ForEach(CourseCategories.all, id: \.self) { category in
                                Button {
                                    selectedCategory = category
                                    searchText = ""
                                } label: {
                                    CategoryCard(
                                        title: category,
                                        icon: iconForCategory(category),
                                        color: colorForCategory(category)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }

                } else if let category = selectedCategory {
                    VStack(spacing: 12) {

                        HStack(spacing: 12) {
                            Button {
                                selectedCategory = nil
                                searchText = ""
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.headline)
                            }

                            Text(category)
                                .font(.title2.bold())

                            Spacer()
                        }
                        .padding(.horizontal)

                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)

                            TextField("Search in \(category)", text: $searchText)
                                .textFieldStyle(.plain)

                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(AppTheme.secondaryGroupedBackground)
                        .cornerRadius(14)
                        .padding(.horizontal)

                        ScrollView {
                            let filteredCourses = browseOnlyCourses
                                .filter { $0.category == category }
                                .filter {
                                    searchText.isEmpty ||
                                    $0.title.localizedCaseInsensitiveContains(searchText) ||
                                    $0.description.localizedCaseInsensitiveContains(searchText)
                                }

                            if filteredCourses.isEmpty {
                                LearnerEmptyState(
                                    icon: "magnifyingglass",
                                    title: "No courses found",
                                    message: "Try another keyword"
                                )
                                .padding(.top, 60)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(filteredCourses) { course in
                                        NavigationLink(
                                            destination: LearnerCourseDetailView(
                                                course: course,
                                                isEnrolled: isEnrolled(course),
                                                userId: user.id,
                                                onEnroll: {
                                                    await enroll(course)
                                                }
                                            )
                                        ) {
                                            PublishedCourseCard(
                                                course: course,
                                                isEnrolled: isEnrolled(course),
                                                onEnroll: {
                                                    await enroll(course)
                                                }
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding()
                            }
                        }

                        Spacer()
                    }
                }
            }
            .navigationTitle(selectedCategory == nil ? "Search" : "")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive, action: handleLogout) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                }
            }
        }
        .id(user.id)
    }
}

