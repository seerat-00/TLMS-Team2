//
//  QuestionnaireCompletionView.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import SwiftUI

struct QuestionnaireCompletionView: View {
    @ObservedObject var viewModel: QuestionnaireViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("Questionnaire Completed!")
                .font(.title)
                .fontWeight(.bold)

            Text("Your learning experience is now personalized.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button {
                Task {
                    await viewModel.completeQuestionnaire()
                    dismiss()   // ← go back to dashboard
                }
            } label: {
                Text("Finish")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 20)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}
