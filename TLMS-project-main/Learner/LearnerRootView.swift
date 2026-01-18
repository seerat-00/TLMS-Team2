//
//  LearnerRootView.swift
//  TLMS-project-main
//
//

import SwiftUI

struct LearnerRootView: View {
    let user: User
    @EnvironmentObject var authService: AuthService

    var body: some View {
        LearnerDashboardView(user: user)
            .environmentObject(authService)
    }
}
