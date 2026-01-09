//
//  LearningGoalvIEW.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import Foundation
import SwiftUI

struct LearningGoalView: View {
    @ObservedObject var viewModel: QuestionnaireViewModel

    var body: some View {
        List {
            Section {
                ForEach(LearningGoal.allCases, id: \.self) { goal in
                    HStack {
                        Text(goal.rawValue)
                            .foregroundColor(.primary)

                        Spacer()

                        if viewModel.response.learningGoal == goal {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            viewModel.response.learningGoal = goal
                            viewModel.nextStep()
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Learning Goal")
        .navigationBarTitleDisplayMode(.large)
    }
}

