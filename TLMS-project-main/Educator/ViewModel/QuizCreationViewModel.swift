//
//  QuizCreationViewModel.swift
//  TLMS-project-main
//
//  ViewModel for Quiz Creation Flow
//

import SwiftUI
import Combine

@MainActor
class QuizCreationViewModel: ObservableObject {
    @Published var newQuiz: Quiz
    @Published var selectedCourse: Course?
    @Published var availableCourses: [Course] = []
    
    // Navigation state
    @Published var navigationPath = NavigationPath()
    @Published var shouldDismissToRoot = false
    @Published var saveSuccessMessage: String?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let quizService = QuizService()
    private let courseService = CourseService()
    private let educatorID: UUID
    
    init(educatorID: UUID, courseID: UUID? = nil) {
        self.educatorID = educatorID
        
        // Initialize with a default quiz
        if let courseID = courseID {
            self.newQuiz = Quiz(
                title: "",
                courseID: courseID,
                educatorID: educatorID
            )
        } else {
            // Temporary courseID, will be updated when course is selected
            self.newQuiz = Quiz(
                title: "",
                courseID: UUID(),
                educatorID: educatorID
            )
        }
        
        // Load available courses
        Task {
            await loadCourses()
            
            // If courseID was provided, find and set the selected course
            if let courseID = courseID {
                self.selectedCourse = availableCourses.first { $0.id == courseID }
            }
        }
    }
    
    // MARK: - Load Courses
    
    func loadCourses() async {
        isLoading = true
        let courses = await courseService.fetchCourses(for: educatorID)
        self.availableCourses = courses
        isLoading = false
    }
    
    // MARK: - Question Management
    
    func addQuestion() {
        let newQuestion = Question(
            text: "",
            options: ["", "", "", ""],
            correctAnswerIndices: [0],
            points: 1
        )
        newQuiz.questions.append(newQuestion)
    }
    
    func updateQuestion(_ question: Question) {
        if let index = newQuiz.questions.firstIndex(where: { $0.id == question.id }) {
            newQuiz.questions[index] = question
        }
    }
    
    func deleteQuestion(at index: Int) {
        guard index >= 0 && index < newQuiz.questions.count else { return }
        newQuiz.questions.remove(at: index)
    }
    
    func moveQuestion(from source: IndexSet, to destination: Int) {
        newQuiz.questions.move(fromOffsets: source, toOffset: destination)
    }
    
    // MARK: - Validation
    
    var isQuizValid: Bool {
        !newQuiz.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var canSaveQuiz: Bool {
        isQuizValid && !newQuiz.questions.isEmpty && newQuiz.questions.allSatisfy { $0.isValid }
    }
    
    // MARK: - Quiz Actions
    
    func selectCourse(_ course: Course) {
        self.selectedCourse = course
        self.newQuiz.courseID = course.id
    }
    
    func saveAsDraft() async {
        guard canSaveQuiz else {
            errorMessage = "Please ensure all questions are complete before saving."
            return
        }
        
        newQuiz.status = .draft
        newQuiz.updatedAt = Date()
        
        isLoading = true
        let success = await quizService.saveQuiz(newQuiz)
        isLoading = false
        
        if success {
            saveSuccessMessage = "Quiz saved as draft"
            shouldDismissToRoot = true
        } else {
            errorMessage = quizService.errorMessage ?? "Failed to save quiz"
        }
    }
    
    func publishQuiz() async {
        guard canSaveQuiz else {
            errorMessage = "Please ensure all questions are complete before publishing."
            return
        }
        
        newQuiz.status = .published
        newQuiz.updatedAt = Date()
        
        isLoading = true
        let success = await quizService.saveQuiz(newQuiz)
        isLoading = false
        
        if success {
            saveSuccessMessage = "Quiz published successfully"
            shouldDismissToRoot = true
        } else {
            errorMessage = quizService.errorMessage ?? "Failed to publish quiz"
        }
    }
}
