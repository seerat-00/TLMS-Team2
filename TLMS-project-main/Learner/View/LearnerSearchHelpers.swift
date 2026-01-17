//
//  LearnerSearchHelpers.swift
//  TLMS-project-main
//
//  Created by Chehak on 16/01/26.
//

import Foundation
import SwiftUI


func iconForCategory(_ category: String) -> String {
    switch category {
    case "Programming": return "chevron.left.forwardslash.chevron.right"
    case "Design": return "paintbrush.fill"
    case "Business": return "briefcase.fill"
    case "Data Science": return "chart.bar.fill"
    case "Marketing": return "megaphone.fill"
    case "Photography": return "camera.fill"
    case "Music": return "music.note"
    case "Writing": return "pencil.and.outline"
    default: return "book.fill"
    }
}

func colorForCategory(_ category: String) -> Color {
    switch category {
    case "Programming": return Color(red: 0.2, green: 0.6, blue: 1.0)
    case "Design": return Color(red: 1.0, green: 0.4, blue: 0.6)
    case "Business": return Color(red: 0.4, green: 0.8, blue: 0.4)
    case "Marketing": return Color(red: 1.0, green: 0.6, blue: 0.2)
    case "Data Science": return Color(red: 0.6, green: 0.4, blue: 1.0)
    default: return AppTheme.primaryBlue
    }
}
