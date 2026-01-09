//
//  QuestionnaireResponse.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import Foundation

struct QuestionnaireResponse: Codable {
    let userId: String

    var learningGoal: LearningGoal?
    var skillLevel: SkillLevel?
    var interests: [Interest]
    var timeAvailability: TimeAvailability?
    var learningFormats: [LearningFormat]
    var isCompleted: Bool

    init(userId: String) {
        self.userId = userId
        self.learningGoal = nil
        self.skillLevel = nil
        self.interests = []
        self.timeAvailability = nil
        self.learningFormats = []
        self.isCompleted = false
    }
}

extension QuestionnaireResponse {

    func toSupabasePayload() -> QuestionnaireSupabasePayload {
        QuestionnaireSupabasePayload(
            user_id: userId,
            learning_goal: learningGoal?.rawValue,
            skill_level: skillLevel?.rawValue,
            interests: interests.map { $0.rawValue },
            time_availability: timeAvailability?.rawValue,
            learning_formats: learningFormats.map { $0.rawValue },
            is_completed: isCompleted
        )
    }
}

