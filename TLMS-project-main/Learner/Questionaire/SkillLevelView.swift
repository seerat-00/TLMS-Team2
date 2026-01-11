//
//  SkillLevelView.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import Foundation
import SwiftUI

struct SkillLevelView: View {
    @ObservedObject var viewModel: QuestionnaireViewModel

    var body: some View {
        List {
            Section {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    HStack {
                        Text(level.rawValue)

                        Spacer()

                        if viewModel.response.skillLevel == level {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.response.skillLevel = level
                        viewModel.nextStep()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Skill Level")
        .navigationBarTitleDisplayMode(.large)
    }
}
