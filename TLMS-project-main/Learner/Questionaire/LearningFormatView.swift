//
//  LearningFormatView.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import SwiftUI

struct LearningFormatView: View {
    @ObservedObject var viewModel: QuestionnaireViewModel
    @EnvironmentObject var authService: AuthService

    var body: some View {
        List {
            Section {
                ForEach(LearningFormat.allCases, id: \.self) { format in
                    HStack {
                        Text(format.rawValue)
                        Spacer()
                        if viewModel.response.learningFormats.contains(format) {
                            Image(systemName: "checkmark")
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
                Button("Finish") {
                    Task {
                        await viewModel.completeQuestionnaire()
                        authService.entryPoint = nil   // ✅ reset here
                    }
                }
                .disabled(viewModel.response.learningFormats.isEmpty)
            }
        }
        .navigationTitle("Learning Format")
    }
}
