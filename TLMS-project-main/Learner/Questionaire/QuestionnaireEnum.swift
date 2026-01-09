//
//  QuestionnaireModel.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import Foundation

enum LearningGoal: String, CaseIterable, Codable {
    case careerGrowth = "Career Growth"
    case skillUpgrade = "Skill Upgrade"
    case academic = "Academic Learning"
    case personal = "Personal Interest"
}

enum SkillLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

enum Interest: String, CaseIterable, Codable {
    case ios = "iOS Development"
    case backend = "Backend Development"
    case ai = "AI / ML"
    case dsa = "Data Structures"
    case uiux = "UI / UX"
}

enum TimeAvailability: String, CaseIterable, Codable {
    case lessThan3 = "< 3 hrs/week"
    case threeToSix = "3–6 hrs/week"
    case moreThanSix = "6+ hrs/week"
}

enum LearningFormat: String, CaseIterable, Codable {
    case video = "Video"
    case reading = "Reading"
    case handsOn = "Hands-on"
}

enum QuestionnaireStep: Int, CaseIterable {
    case goal, skill, interests, time, format, completion
}

enum AuthEntryPoint {
    case signup
    case login
}


