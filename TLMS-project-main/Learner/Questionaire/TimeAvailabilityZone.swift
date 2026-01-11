//
//  TimeAvailabilityZone.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import Foundation
import SwiftUI

struct TimeAvailabilityView: View {
    @ObservedObject var viewModel: QuestionnaireViewModel

    var body: some View {
        List {
            Section {
                ForEach(TimeAvailability.allCases, id: \.self) { time in
                    HStack {
                        Text(time.rawValue)

                        Spacer()

                        if viewModel.response.timeAvailability == time {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.response.timeAvailability = time
                        viewModel.nextStep()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Weekly Time")
        .navigationBarTitleDisplayMode(.large)
    }
}
