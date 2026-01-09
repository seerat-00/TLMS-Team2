//
//  LearnerRootView.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import SwiftUI

struct LearnerRootView: View {
    let user: User
    @EnvironmentObject var authService: AuthService
    @StateObject private var questionnaireVM: QuestionnaireViewModel

    init(user: User) {
        self.user = user
        _questionnaireVM = StateObject(
            wrappedValue: QuestionnaireViewModel(userId: user.id.uuidString)
        )
    }

    var body: some View {
        Group {
            // 🆕 Signup → always questionnaire
            if authService.entryPoint == .signup {
                QuestionnaireContainerView(viewModel: questionnaireVM)

            // 🔐 Login + completed → dashboard
            } else if questionnaireVM.response.isCompleted {
                LearnerDashboardView(user: user)

            // 🔐 Login + not completed → questionnaire
            } else {
                QuestionnaireContainerView(viewModel: questionnaireVM)
            }
        }
    }
}
