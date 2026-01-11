//
//  InterestsView.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import Foundation
import SwiftUI

struct InterestsView: View {
    @ObservedObject var viewModel: QuestionnaireViewModel

    var body: some View {
        List {
            Section(footer: Text("Select all that apply")) {
                ForEach(Interest.allCases, id: \.self) { interest in
                    HStack {
                        Text(interest.rawValue)

                        Spacer()

                        if viewModel.response.interests.contains(interest) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if viewModel.response.interests.contains(interest) {
                            viewModel.response.interests.removeAll { $0 == interest }
                        } else {
                            viewModel.response.interests.append(interest)
                        }
                    }
                }
            }

            Section {
                HStack {
                    Spacer()

                    Button("Continue") {
                        viewModel.nextStep()
                    }
                    .font(.body.weight(.semibold))
                    .disabled(viewModel.response.interests.isEmpty)

                    Spacer()
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Interests")
        .navigationBarTitleDisplayMode(.large)
    }
}
