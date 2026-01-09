//
//  QuestionnaireCompletionView.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import Foundation
import SwiftUI

struct QuestionnaireCompletionView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundColor(.green)

            Text("Questionnaire Completed!")
                .font(.title)

            Text("Your learning experience is now personalized.")
                .multilineTextAlignment(.center)
        }
    }
}
