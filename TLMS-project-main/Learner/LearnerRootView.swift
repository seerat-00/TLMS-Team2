//
//  LearnerRootView.swift
//  TLMS-project-main
//

import SwiftUI

struct LearnerRootView: View {
    let user: User
    @EnvironmentObject var authService: AuthService
    @StateObject private var questionnaireVM: QuestionnaireViewModel

    init(user: User) {
        self.user = user
        _questionnaireVM = StateObject(
            wrappedValue: QuestionnaireViewModel(
                userId: user.id.uuidString
            )
        )
    }

    var body: some View {
        NavigationStack {
            Group {

                // ⏳ Loading
                if questionnaireVM.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)

                // 🆕 Signup → Questionnaire
                } else if authService.entryPoint == .signup {
                    QuestionnaireContainerView(
                        viewModel: questionnaireVM,
                        mode: .onboarding
                    )

                // 🔐 Completed → Dashboard
                } else if questionnaireVM.response.isCompleted {
                    LearnerDashboardView(user: user)

                // 🔐 Login but incomplete → Questionnaire
                } else {
                    QuestionnaireContainerView(
                        viewModel: questionnaireVM,
                        mode: .onboarding
                    )
                }
            }
        }
        .environmentObject(authService)
    }
}
