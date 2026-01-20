import Foundation

struct CourseDeadline: Identifiable, Codable {
    var id: UUID
    var courseId: UUID
    var lessonId: UUID?
    var quizId: UUID?
    
    var title: String
    var deadlineAt: Date
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case courseId = "course_id"
        case lessonId = "lesson_id"
        case quizId = "quiz_id"
        case title
        case deadlineAt = "deadline_at"
        case createdAt = "created_at"
    }
}
