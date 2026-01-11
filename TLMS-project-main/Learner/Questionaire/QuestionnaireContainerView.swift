//
//  QuestionnaireContainerView.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import SwiftUI

struct QuestionnaireContainerView: View {
    @ObservedObject var viewModel: QuestionnaireViewModel
    let mode: QuestionnaireMode

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            // Progress only during onboarding
            if mode == .onboarding {
                ProgressView(
                    value: Double(viewModel.stepIndex + 1),
                    total: Double(viewModel.totalSteps)
                )
                .progressViewStyle(.linear)
                .padding(.horizontal)
            }

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
                LearningFormatView(
                    viewModel: viewModel,
                    mode: mode
                )
            default:
                QuestionnaireCompletionView(viewModel: viewModel)
            }

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .toolbar {

            // ✅ BACK (step > 0, all modes)
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.stepIndex > 0 {
                    Button {
                        viewModel.previousStep()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }

            // ✅ SKIP (onboarding only)
            ToolbarItem(placement: .navigationBarTrailing) {
                if mode == .onboarding {
                    Button("Skip") {
                        Task {
                            await viewModel.skipQuestionnaire()
                            dismiss()
                        }
                    }
                    .disabled(viewModel.hasStartedAnswering)
                }
            }
        }
    }
}
