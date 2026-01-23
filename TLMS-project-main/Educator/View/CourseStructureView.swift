//
//  CourseStructureView.swift
//  TLMS-project-main
//
//  Step 2: Course Structure (Modules & Lessons)
//

import SwiftUI

struct CourseStructureView: View {
    @ObservedObject var viewModel: CourseCreationViewModel
    @State private var isEditingModuleID: UUID?
    @State private var editingTitle = ""
    @State private var editingDescription = ""
    @State private var expandedModules: Set<UUID> = []
    @State private var newLessonName = ""
    @State private var showingAddLessonFor: UUID?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.groupedBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Course Structure")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(AppTheme.primaryText)
                            .lineLimit(1)
                        
                        Text("Organize modules and lessons. Keep it simple and effective.")
                            .font(.body)
                            .foregroundColor(AppTheme.secondaryText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Modules List
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Curriculum")
                                .font(.title2.bold())
                                .foregroundColor(AppTheme.primaryText)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring()) {
                                    viewModel.addModule()
                                    if let lastModule = viewModel.newCourse.modules.last {
                                        expandedModules.insert(lastModule.id)
                                    }
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Module")
                                }
                                .font(.subheadline.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppTheme.primaryBlue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 5, y: 3)
                            }
                        }
                        .padding(.horizontal)
                        
                        if viewModel.newCourse.modules.isEmpty {
                            EmptyStateView(
                                icon: "folder.badge.plus",
                                title: "No Modules Yet",
                                message: "Start building your curriculum."
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                        } else {
                            ForEach(viewModel.newCourse.modules) { module in
                                ExpandableModuleCard(
                                    module: module,
                                    viewModel: viewModel,
                                    isExpanded: expandedModules.contains(module.id),
                                    isEditing: isEditingModuleID == module.id,
                                    editingTitle: $editingTitle,
                                    editingDescription: $editingDescription,
                                    newLessonName: $newLessonName,
                                    showingAddLessonFor: $showingAddLessonFor,
                                    onToggleExpand: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if expandedModules.contains(module.id) {
                                                expandedModules.remove(module.id)
                                            } else {
                                                expandedModules.insert(module.id)
                                            }
                                        }
                                    },
                                    onEditStart: {
                                        editingTitle = module.title
                                        editingDescription = module.description ?? ""
                                        isEditingModuleID = module.id
                                    },
                                    onEditEnd: {
                                        if !editingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            var updatedModule = module
                                            updatedModule.title = editingTitle
                                            updatedModule.description = editingDescription.isEmpty ? nil : editingDescription
                                            viewModel.updateModule(updatedModule)
                                        }
                                        isEditingModuleID = nil
                                    },
                                    onDelete: {
                                        if let index = viewModel.newCourse.modules.firstIndex(where: { $0.id == module.id }) {
                                            viewModel.deleteModule(at: IndexSet(integer: index))
                                        }
                                    }
                                )
                            }
                        }
                    }
                    
                    // Preview Button
                    NavigationLink(destination: CoursePreviewView(viewModel: viewModel)) {
                        HStack(spacing: 8) {
                            Text("Preview Course")
                                .font(.headline)
                            Image(systemName: "eye.fill")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.newCourse.modules.isEmpty ? Color.gray.opacity(0.3) : AppTheme.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: viewModel.newCourse.modules.isEmpty ? .clear : AppTheme.primaryBlue.opacity(0.3), radius: 10, y: 5)
                    }
                    .disabled(viewModel.newCourse.modules.isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 60)
                }
            }
        }
    }
}

// Ensure LessonNavigation is Hashable for NavigationPath
enum LessonNavigation: Hashable {
    case quiz(moduleID: UUID, lesson: Lesson)
    case content(moduleID: UUID, lesson: Lesson)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .quiz(let mID, let lesson):
            hasher.combine(0)
            hasher.combine(mID)
            hasher.combine(lesson.id)
        case .content(let mID, let lesson):
            hasher.combine(1)
            hasher.combine(mID)
            hasher.combine(lesson.id)
        }
    }
    
    static func == (lhs: LessonNavigation, rhs: LessonNavigation) -> Bool {
        switch (lhs, rhs) {
        case (.quiz(let m1, let l1), .quiz(let m2, let l2)):
            return m1 == m2 && l1.id == l2.id
        case (.content(let m1, let l1), .content(let m2, let l2)):
            return m1 == m2 && l1.id == l2.id
        default:
            return false
        }
    }
}

// MARK: - Expandable Module Card

struct ExpandableModuleCard: View {
    let module: Module
    @ObservedObject var viewModel: CourseCreationViewModel
    let isExpanded: Bool
    let isEditing: Bool
    @Binding var editingTitle: String
    @Binding var editingDescription: String
    @Binding var newLessonName: String
    @Binding var showingAddLessonFor: UUID?
    let onToggleExpand: () -> Void
    let onEditStart: () -> Void
    let onEditEnd: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Module Header
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 16) {
                    // Expand Icon
                    Button(action: onToggleExpand) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.primaryBlue)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.primaryBlue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if isEditing {
                            TextField("Module Title", text: $editingTitle)
                                .font(.headline)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(8)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(8)
                        } else {
                            Text(module.title.isEmpty ? "Untitled Module" : module.title)
                                .font(.headline)
                                .foregroundColor(AppTheme.primaryText)
                                .lineLimit(1)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 10))
                                Text("\(module.lessons.count) Lessons")
                                    .font(.caption.bold())
                                    .lineLimit(1)
                            }
                            .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Actions
                    HStack(spacing: 8) {
                        if isEditing {
                            Button(action: onEditEnd) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(AppTheme.successGreen)
                                    .clipShape(Circle())
                            }
                        } else {
                            Button(action: onEditStart) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.primaryBlue)
                                    .frame(width: 32, height: 32)
                                    .background(AppTheme.primaryBlue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        
                        Button(action: { showDeleteAlert = true }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .frame(width: 32, height: 32)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
                
                if isEditing {
                    TextField("Brief Description (optional)", text: $editingDescription)
                        .font(.subheadline)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(8)
                        .lineLimit(1)
                }
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            
            // Lessons List
            if isExpanded && !isEditing {
                Divider().padding(.horizontal)
                
                VStack(spacing: 12) {
                    ForEach(module.lessons) { lesson in
                        LessonInlineRow(
                            lesson: lesson,
                            moduleID: module.id,
                            viewModel: viewModel
                        )
                    }
                    
                    // Add Lesson UI
                    if showingAddLessonFor == module.id {
                        HStack(spacing: 12) {
                            TextField("Enter lesson title", text: $newLessonName)
                                .font(.subheadline)
                                .padding(10)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(8)
                                .lineLimit(1)
                            
                            Button(action: {
                                if !newLessonName.isEmpty {
                                    viewModel.addLesson(to: module.id, title: newLessonName)
                                    newLessonName = ""
                                    showingAddLessonFor = nil
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.successGreen)
                            }
                            
                            Button(action: { showingAddLessonFor = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    } else {
                        Button(action: { showingAddLessonFor = module.id }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("New Lesson")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.primaryBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppTheme.primaryBlue.opacity(0.05))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.02))
            }
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .padding(.horizontal)
        .alert("Delete Module", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("This will remove all lessons in this module.")
        }
    }
}

// MARK: - Lesson Inline Row

struct LessonInlineRow: View {
    let lesson: Lesson
    let moduleID: UUID
    @ObservedObject var viewModel: CourseCreationViewModel
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Type Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.primaryBlue.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: lesson.type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.primaryBlue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.title.isEmpty ? "Untitled Lesson" : lesson.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(lesson.type.shortName)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(4)
                        .lineLimit(1)
                    
                    if lesson.hasContent {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.successGreen)
                    }
                }
                .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 10) {
                // Type Picker
                Menu {
                    ForEach(ContentType.allCases) { type in
                        Button(action: {
                            updateType(to: type)
                        }) {
                            Label(type.shortName, systemImage: type.icon)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                // Edit Button
                NavigationLink(destination: destinationView(for: lesson)) {
                    Text(lesson.hasContent ? "Edit" : "Build")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: { showDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
        .alert("Delete Lesson", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let mIdx = viewModel.newCourse.modules.firstIndex(where: { $0.id == moduleID }),
                   let lIdx = viewModel.newCourse.modules[mIdx].lessons.firstIndex(where: { $0.id == lesson.id }) {
                    viewModel.deleteLesson(moduleID: moduleID, at: IndexSet(integer: lIdx))
                }
            }
        }
    }
    
    private func updateType(to type: ContentType) {
        var updated = lesson
        updated.type = type
        viewModel.updateLesson(moduleID: moduleID, lesson: updated)
    }
    
    @ViewBuilder
    private func destinationView(for lesson: Lesson) -> some View {
        if lesson.type == .quiz {
            LessonQuizEditorView(
                viewModel: viewModel,
                moduleID: moduleID,
                lessonID: lesson.id,
                lessonTitle: lesson.title
            )
        } else {
            LessonContentEditorView(
                viewModel: viewModel,
                moduleID: moduleID,
                lessonID: lesson.id
            )
        }
    }
}

#Preview {
    CourseStructureView(viewModel: CourseCreationViewModel(educatorID: UUID()))
}
