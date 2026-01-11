//
//  LearningFormatView.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import SwiftUI

struct LearningFormatView: View {
    @ObservedObject var viewModel: QuestionnaireViewModel
    let mode: QuestionnaireMode

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService   // ✅ REQUIRED

    var body: some View {
        List {
            Section {
                ForEach(LearningFormat.allCases, id: \.self) { format in
                    HStack {
                        Text(format.rawValue)
                        Spacer()
                        if viewModel.response.learningFormats.contains(format) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if viewModel.response.learningFormats.contains(format) {
                            viewModel.response.learningFormats.removeAll { $0 == format }
                        } else {
                            viewModel.response.learningFormats.append(format)
                        }
                    }
                }
            }

            Section {
                HStack {
                    Spacer()

                    Button(buttonTitle) {
                        Task {
                            await viewModel.completeQuestionnaire()

                            switch mode {
                            case .edit:
                                dismiss()                      // edit → pop

                            case .onboarding:
                                authService.entryPoint = nil   // onboarding → dashboard
                            }
                        }
                    }
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(viewModel.response.learningFormats.isEmpty)

                    Spacer()
                }
            }
        }
        .navigationTitle("Learning Format")
        .navigationBarTitleDisplayMode(.large)
    }

    private var buttonTitle: String {
        mode == .edit ? "Save" : "Finish"
    }
}

