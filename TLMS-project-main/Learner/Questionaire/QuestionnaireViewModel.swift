//
//  QuestionnaireViewModel.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class QuestionnaireViewModel: ObservableObject {

    @Published var stepIndex: Int = 0
    @Published var response: QuestionnaireResponse

    // ✅ NEW
    @Published var isLoading: Bool = true

    private let service = QuestionnaireService()
    let totalSteps = 5

    var hasStartedAnswering: Bool {
        response.learningGoal != nil ||
        response.skillLevel != nil ||
        !response.interests.isEmpty ||
        response.timeAvailability != nil ||
        !response.learningFormats.isEmpty
    }

    init(userId: String) {
        self.response = QuestionnaireResponse(userId: userId)

        Task {
            defer { isLoading = false }   // ✅ always unset loading

            if let saved = try? await service.fetch(userId: userId) {
                self.response = saved
            }
        }
    }

    func nextStep() {
        guard stepIndex < totalSteps else { return }

        let snapshot = response
        stepIndex += 1

        Task {
            try? await service.save(snapshot)
        }
    }

    func previousStep() {
        guard stepIndex > 0 else { return }
        stepIndex -= 1
    }

    func skipQuestionnaire() async {
        response.isCompleted = false
        try? await service.save(response)
    }

    func completeQuestionnaire() async {
        response.isCompleted = true
        try? await service.save(response)
    }
}
