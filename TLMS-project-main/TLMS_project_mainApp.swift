//
//  TLMS_project_mainApp.swift
//  TLMS-project-main
//
//  Created by Nihar Sandhu on 07/01/26.
//

import SwiftUI

@main
struct TLMS_project_mainApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            AuthenticationView()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .preferredColorScheme(.light) // Optional
                .id(themeManager.currentTheme.rawValue) // Force full rebuild on theme change
        }
    }
}
