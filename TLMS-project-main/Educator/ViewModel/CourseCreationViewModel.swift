//
//  CourseCreationViewModel.swift
//  TLMS-project-main
//
//  ViewModel for Course Creation Flow
//

import SwiftUI
import Combine

@MainActor
class CourseCreationViewModel: ObservableObject {
    @Published var newCourse: Course
    
    // Navigation state
    @Published var navigationPath = NavigationPath()
    
    init(educatorID: UUID) {
        self.newCourse = Course(
            title: "",
            description: "",
            category: "",
            educatorID: educatorID 
        )
    }
    
    // MARK: - Module Management
    
    func addModule() {
        let newModule = Module(title: "New Module \(newCourse.modules.count + 1)")
        newCourse.modules.append(newModule)
    }
    
    func updateModule(_ module: Module) {
        if let index = newCourse.modules.firstIndex(where: { $0.id == module.id }) {
            newCourse.modules[index] = module
        }
    }
    
    func deleteModule(at offsets: IndexSet) {
        newCourse.modules.remove(atOffsets: offsets)
    }
    
    func moveModule(from source: IndexSet, to destination: Int) {
        newCourse.modules.move(fromOffsets: source, toOffset: destination)
    }
    
    // MARK: - Lesson Management
    
    func addLesson(to moduleID: UUID, title: String) {
        guard let moduleIndex = newCourse.modules.firstIndex(where: { $0.id == moduleID }) else { return }
        
        let newLesson = Lesson(
            title: title,
            type: .text // Default type, can be changed later
        )
        newCourse.modules[moduleIndex].lessons.append(newLesson)
    }
    
    func updateLesson(moduleID: UUID, lesson: Lesson) {
        guard let moduleIndex = newCourse.modules.firstIndex(where: { $0.id == moduleID }),
              let lessonIndex = newCourse.modules[moduleIndex].lessons.firstIndex(where: { $0.id == lesson.id }) else { return }
        
        newCourse.modules[moduleIndex].lessons[lessonIndex] = lesson
    }
    
    func deleteLesson(moduleID: UUID, at offsets: IndexSet) {
        guard let moduleIndex = newCourse.modules.firstIndex(where: { $0.id == moduleID }) else { return }
        newCourse.modules[moduleIndex].lessons.remove(atOffsets: offsets)
    }
    
    func moveLesson(moduleID: UUID, from source: IndexSet, to destination: Int) {
        guard let moduleIndex = newCourse.modules.firstIndex(where: { $0.id == moduleID }) else { return }
        newCourse.modules[moduleIndex].lessons.move(fromOffsets: source, toOffset: destination)
    }
    
    
    // MARK: - Course Actions
    
    private let courseService = CourseService()
    
    var isCourseInfoValid: Bool {
        !newCourse.title.isEmpty && !newCourse.description.isEmpty && !newCourse.category.isEmpty
    }
    
    func saveDraft() {
        Task {
            newCourse.status = .draft
            newCourse.updatedAt = Date()
            let success = await courseService.saveCourse(newCourse)
            if success {
                print("Draft saved successfully")
            }
        }
    }
    
    func sendToReview() {
        Task {
            newCourse.status = .pendingReview
            newCourse.updatedAt = Date()
            let success = await courseService.saveCourse(newCourse)
            if success {
                print("Course sent to review")
            }
        }
    }
}
