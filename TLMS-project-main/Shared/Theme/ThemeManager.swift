//
//  ThemeManager.swift
//  TLMS-project-main
//
//  Manages app-wide theme state and persistence
//

import SwiftUI
import Combine

enum ThemeType: String, CaseIterable, Codable, Identifiable {
    case standard = "Standard"
    case deuteranopia = "Deuteranopia"
    case protanopia = "Protanopia"
    case tritanopia = "Tritanopia"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .standard: return "Default / Standard"
        case .deuteranopia: return "Deuteranopia Friendly (Green–Red safe)"
        case .protanopia: return "Protanopia Friendly (Red weak safe)"
        case .tritanopia: return "Tritanopia Friendly (Blue–Yellow safe)"
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: ThemeType = .standard {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    private init() {
        if let savedRaw = UserDefaults.standard.string(forKey: "selectedTheme"),
           let loadedTheme = ThemeType(rawValue: savedRaw) {
            self.currentTheme = loadedTheme
        }
    }
    
    func setTheme(_ theme: ThemeType) {
        currentTheme = theme
    }
    
    // MARK: - Color Palettes
    
    var primaryColor: Color {
        switch currentTheme {
        case .standard:
            return Color(hue: 0.58, saturation: 0.85, brightness: 0.95) // Sophisticated Blue
        case .deuteranopia:
            return Color(red: 0.1, green: 0.45, blue: 0.8) // High contrast blue
        case .protanopia:
            return Color(red: 0.2, green: 0.6, blue: 0.9) // Clear blue
        case .tritanopia:
            return Color(red: 0.9, green: 0.2, blue: 0.4) // Distinct red/pink
        }
    }
    
    var accentColor: Color {
        switch currentTheme {
        case .standard:
            return Color(hue: 0.75, saturation: 0.70, brightness: 0.90) // Purple
        case .deuteranopia:
            return Color(red: 1.0, green: 0.75, blue: 0.0) // Yellow (safe)
        case .protanopia:
            return Color(red: 1.0, green: 0.85, blue: 0.0) // Gold
        case .tritanopia:
            return Color(red: 0.0, green: 1.0, blue: 1.0) // Cyan
        }
    }
    
    var successColor: Color {
        switch currentTheme {
        case .standard:
            return Color(hue: 0.33, saturation: 0.75, brightness: 0.65) // Green
        case .deuteranopia:
             // Avoid green/red confusion. Use Blue for success
            return Color(red: 0.0, green: 0.4, blue: 0.9)
        case .protanopia:
             // Avoid green/red confusion. Use Teal/Blue
            return Color(red: 0.0, green: 0.5, blue: 0.8)
        case .tritanopia:
             // Green is okay for Tritanopia (Blue-blind)
            return Color(red: 0.0, green: 0.7, blue: 0.4)
        }
    }
    
    var errorColor: Color {
        switch currentTheme {
        case .standard:
            return Color(hue: 0.98, saturation: 0.85, brightness: 0.90) // Red
        case .deuteranopia:
            // Avoid red. Use Dark Orange/Brown or Black
            return Color(red: 0.6, green: 0.2, blue: 0.0)
        case .protanopia:
             // Avoid weak red. Use Dark Grey or very dark blue
            return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .tritanopia:
             // Red is distinct for tritanopia
            return Color(hue: 0.98, saturation: 0.85, brightness: 0.90)
        }
    }
    
    var warningColor: Color {
        switch currentTheme {
        case .standard:
            return Color(hue: 0.08, saturation: 0.85, brightness: 0.95) // Orange
        case .deuteranopia:
            // Yellows can be tricky but usually okay if bright
            return Color(red: 1.0, green: 0.9, blue: 0.1)
        case .protanopia:
             return Color(red: 1.0, green: 0.9, blue: 0.0)
        case .tritanopia:
            // Avoid yellows. Use a light magenta or grey
             return Color(red: 1.0, green: 0.5, blue: 0.8)
        }
    }
}
