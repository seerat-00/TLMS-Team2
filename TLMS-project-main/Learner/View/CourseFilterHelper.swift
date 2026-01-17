//
//  CourseFilterHelper.swift
//  TLMS-project-main
//

import Foundation

struct CourseFilterHelper {

    static func filterAndSort(
        courses: [Course],
        selectedCategory: String?,
        searchText: String,
        sortOption: CourseSortOption
    ) -> [Course] {

        var working = courses

        if let category = selectedCategory {
            working = working.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            working = working.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return sortCourses(working, by: sortOption)
    }

    private static func sortCourses(
        _ courses: [Course],
        by option: CourseSortOption
    ) -> [Course] {

        switch option {
        case .relevance:
            return courses.sorted {
                if $0.enrollmentCount == $1.enrollmentCount {
                    return $0.createdAt > $1.createdAt
                }
                return $0.enrollmentCount > $1.enrollmentCount
            }

        case .popularity:
            return courses.sorted {
                $0.enrollmentCount > $1.enrollmentCount
            }

        case .newest:
            return courses.sorted {
                $0.createdAt > $1.createdAt
            }
        }
    }
}
