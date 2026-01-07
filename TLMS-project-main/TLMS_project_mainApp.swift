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
    
    var body: some Scene {
        WindowGroup {
            AuthenticationView()
                .environmentObject(authService)
        }
    }
}
