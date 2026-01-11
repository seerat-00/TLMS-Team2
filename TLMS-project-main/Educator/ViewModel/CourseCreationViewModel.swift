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
    @Published var shouldDismissToRoot = false
    @Published var saveSuccessMessage: String?
    @Published var isLoadingCourse = false
    
    private let courseService = CourseService()
    
    init(educatorID: UUID, existingCourse: DashboardCourse? = nil) {
        if let existingCourse = existingCourse {
            // Initialize with placeholder, will load full course data
            self.newCourse = Course(
                id: existingCourse.id,
                title: existingCourse.title,
                description: "",
                category: "",
                educatorID: educatorID
            )
            
            // Load full course data asynchronously
            Task {
                await loadCourse(courseID: existingCourse.id)
            }
        } else {
            // Creating new course
            self.newCourse = Course(
                title: "",
                description: "",
                category: "",
                educatorID: educatorID 
            )
        }
    }
    
    // MARK: - Load Course
    
    func loadCourse(courseID: UUID) async {
        isLoadingCourse = true
        if let course = await courseService.fetchCourse(by: courseID) {
            self.newCourse = course
        }
        isLoadingCourse = false
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
    
    
    var isCourseInfoValid: Bool {
        !newCourse.title.isEmpty && !newCourse.description.isEmpty && !newCourse.category.isEmpty
    }
    
    func saveDraft() async {
        newCourse.status = .draft
        newCourse.updatedAt = Date()
        let success = await courseService.saveCourse(newCourse)
        if success {
            saveSuccessMessage = "Course saved as draft"
            shouldDismissToRoot = true
        }
    }
    
    func sendToReview() async {
        newCourse.status = .pendingReview
        newCourse.updatedAt = Date()
        let success = await courseService.saveCourse(newCourse)
        if success {
            saveSuccessMessage = "Course sent for review"
            shouldDismissToRoot = true
        }
    }
}
