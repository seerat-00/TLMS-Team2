//
//  QuestionnaireContainerView.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import SwiftUI

struct QuestionnaireContainerView: View {
    @ObservedObject var viewModel: QuestionnaireViewModel
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationStack {
            VStack {
                ProgressView(
                    value: Double(viewModel.stepIndex + 1),
                    total: Double(viewModel.totalSteps)
                )
                .progressViewStyle(.linear)
                .padding(.horizontal)

                switch viewModel.stepIndex {
                case 0:
                    LearningGoalView(viewModel: viewModel)
                case 1:
                    SkillLevelView(viewModel: viewModel)
                case 2:
                    InterestsView(viewModel: viewModel)
                case 3:
                    TimeAvailabilityView(viewModel: viewModel)
                case 4:
                    LearningFormatView(viewModel: viewModel)
                default:
                    QuestionnaireCompletionView()
                }

                Spacer()
            }
            .padding()
            .toolbar {
                // BACK
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.previousStep()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    .disabled(viewModel.stepIndex == 0)
                }

                // SKIP
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        Task {
                            await viewModel.skipQuestionnaire()
                            authService.entryPoint = nil   // ✅ reset here
                        }
                    }
                    .disabled(viewModel.hasStartedAnswering)
                }
            }
        }
    }
}
