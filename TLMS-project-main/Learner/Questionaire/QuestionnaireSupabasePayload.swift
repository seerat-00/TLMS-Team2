//
//  QuestionnaireSupabasePayload.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import Foundation

struct QuestionnaireSupabasePayload: Encodable {
    let user_id: String
    let learning_goal: String?
    let skill_level: String?
    let interests: [String]
    let time_availability: String?
    let learning_formats: [String]
    let is_completed: Bool
}

