//
//  CourseSortOption.swift
//  TLMS-project-main
//
//  Enum for course sorting options
//

import Foundation

enum CourseSortOption: String, CaseIterable, Identifiable {
    case relevance = "Relevance"
    case popularity = "Popularity"
    case newest = "Newest"
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue
    }
    
    var icon: String {
        switch self {
        case .relevance:
            return "star.fill"
        case .popularity:
            return "person.3.fill"
        case .newest:
            return "clock.fill"
        }
    }
    
    var description: String {
        switch self {
        case .relevance:
            return "Best match for you"
        case .popularity:
            return "Most enrolled"
        case .newest:
            return "Recently added"
        }
    }
}
