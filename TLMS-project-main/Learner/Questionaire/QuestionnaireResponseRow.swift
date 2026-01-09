//
//  QuestionnaireResponseRow.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import Foundation

struct QuestionnaireResponseRow: Decodable {
    let user_id: UUID
    let learning_goal: String?
    let skill_level: String?
    let interests: [String]
    let time_availability: String?
    let learning_formats: [String]
    let is_completed: Bool
}

extension QuestionnaireResponseRow {
    func toModel() -> QuestionnaireResponse {
        var response = QuestionnaireResponse(userId: user_id.uuidString)
        response.learningGoal = learning_goal.flatMap(LearningGoal.init(rawValue:))
        response.skillLevel = skill_level.flatMap(SkillLevel.init(rawValue:))
        response.interests = interests.compactMap(Interest.init(rawValue:))
        response.timeAvailability = time_availability.flatMap(TimeAvailability.init(rawValue:))
        response.learningFormats = learning_formats.compactMap(LearningFormat.init(rawValue:))
        response.isCompleted = is_completed
        return response
    }
}

