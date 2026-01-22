//
//  ThemeSelectionView.swift
//  TLMS-project-main
//
//  Screen for selecting accessibility color themes
//

import SwiftUI

struct ThemeSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.groupedBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Color Mode")
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("Choose a theme optimized for your vision.")
                            .font(.body)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Theme Options
                    VStack(spacing: 16) {
                        ForEach(ThemeType.allCases) { theme in
                            ThemeOptionCard(theme: theme, isSelected: themeManager.currentTheme == theme) {
                                withAnimation {
                                    themeManager.setTheme(theme)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThemeOptionCard: View {
    let theme: ThemeType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Color Preview
                Circle()
                    .fill(previewColor(for: theme))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .shadow(color: .black.opacity(0.1), radius: 2)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.rawValue)
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(theme.description)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppTheme.primaryBlue)
                } else {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundColor(AppTheme.secondaryText.opacity(0.3))
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.primaryBlue : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // Helper to get a representative color for the preview
    func previewColor(for theme: ThemeType) -> Color {
        switch theme {
        case .standard:
            return Color(hue: 0.58, saturation: 0.85, brightness: 0.95)
        case .deuteranopia:
            return Color(red: 0.1, green: 0.45, blue: 0.8)
        case .protanopia:
            return Color(red: 0.2, green: 0.6, blue: 0.9)
        case .tritanopia:
            return Color(red: 0.9, green: 0.2, blue: 0.4)
        }
    }
}

#Preview {
    NavigationView {
        ThemeSelectionView()
            .environmentObject(ThemeManager.shared)
    }
}
