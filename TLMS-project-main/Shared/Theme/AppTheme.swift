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
    static let primaryAccent = primaryBlue // Alias for compatibility
    
    // Complementary/Accent Colors
    static let secondaryBlue = Color(red: 235/255, green: 243/255, blue: 255/255) // Light blue background
    static let secondaryAccent = Color(red: 6/255, green: 182/255, blue: 212/255) // Cyan
    static let successGreen = Color(red: 26/255, green: 137/255, blue: 23/255)
    static let warningOrange = Color(red: 232/255, green: 119/255, blue: 34/255)
    static let errorRed = Color(red: 200/255, green: 0/255, blue: 40/255)
    
    // Backgrounds
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    static let secondaryGroupedBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let background = Color(uiColor: .systemBackground)
    
    // Text
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    
    // MARK: - Gradient Backgrounds (using blue)
    
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primaryBlue, primaryBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [primaryBlue, secondaryAccent],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                groupedBackground,
                secondaryGroupedBackground
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Layout
    
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 10
    static let cardPadding: CGFloat = 16
    static let shadowRadius: CGFloat = 8
    static let smallShadowRadius: CGFloat = 4
}

// MARK: - View Modifiers

extension View {
    func standardCardStyle() -> some View {
        self
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(
                color: Color.black.opacity(0.1),
                radius: AppTheme.smallShadowRadius,
                x: 0,
                y: 2
            )
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.primaryGradient)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(
                color: Color(red: 107/255, green: 47/255, blue: 191/255).opacity(0.3),
                radius: AppTheme.shadowRadius,
                x: 0,
                y: 4
            )
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(AppTheme.primaryAccent)
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.primaryAccent, lineWidth: 2)
            )
    }
    
    func premiumCardStyle() -> some View {
        self
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(
                color: Color.black.opacity(0.08),
                radius: AppTheme.shadowRadius,
                x: 0,
                y: 4
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppTheme.primaryAccent.opacity(0.3),
                                AppTheme.secondaryAccent.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}
