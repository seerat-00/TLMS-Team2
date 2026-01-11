//
//  AppTheme.swift
//  TLMS-project-main
//
//  Shared UI Theme constants for a professional, native iOS look.
//

import SwiftUI

struct AppTheme {
    // MARK: - Colors
    
    // Coursera-like Blue
    static let primaryBlue = Color(red: 0/255, green: 86/255, blue: 210/255) // #0056D2
    
    // Complementary/Accent Colors
    static let secondaryBlue = Color(red: 235/255, green: 243/255, blue: 255/255) // Light blue background
    static let successGreen = Color(red: 26/255, green: 137/255, blue: 23/255)
    static let warningOrange = Color(red: 232/255, green: 119/255, blue: 34/255)
    static let errorRed = Color(red: 200/255, green: 0/255, blue: 40/255)
    
    // Backgrounds
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    static let secondaryGroupedBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let background = Color(uiColor: .systemBackground)
    
    // Text
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    
    // MARK: - Layout
    
    static let cornerRadius: CGFloat = 8 // Standard iOS corner radius, not too rounded
    static let cardPadding: CGFloat = 16
    static let shadowRadius: CGFloat = 2
}

// MARK: - View Modifiers

extension View {
    func standardCardStyle() -> some View {
        self
            .background(AppTheme.secondaryGroupedBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.primaryBlue)
            .cornerRadius(AppTheme.cornerRadius)
    }
}
