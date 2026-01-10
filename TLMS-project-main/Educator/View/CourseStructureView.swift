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
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.newCourse.title)
                            .font(.largeTitle.bold())
                        
                        Text("Design your course by creating modules and lessons")
                            .font(.body)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Modules List
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Modules")
                                .font(.title2.bold())
                            
                            Spacer()
                            
                            Button(action: { 
                                viewModel.addModule()
                                // Auto-expand new module
                                if let lastModule = viewModel.newCourse.modules.last {
                                    expandedModules.insert(lastModule.id)
                                }
                            }) {
                                Label("Add Module", systemImage: "plus")
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.primaryBlue.opacity(0.1))
                                    .foregroundColor(AppTheme.primaryBlue)
                                    .cornerRadius(AppTheme.cornerRadius)
                            }
                        }
                        .padding(.horizontal)
                        
                        if viewModel.newCourse.modules.isEmpty {
                            EmptyStateView(
                                icon: "folder.badge.plus",
                                title: "No Modules Yet",
                                message: "Create a module to start organizing your content."
                            )
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
                                        if expandedModules.contains(module.id) {
                                            expandedModules.remove(module.id)
                                        } else {
                                            expandedModules.insert(module.id)
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
                            .onMove { source, destination in
                                viewModel.moveModule(from: source, to: destination)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Preview Button
                    NavigationLink(destination: CoursePreviewView(viewModel: viewModel)) {
                        HStack(spacing: 8) {
                            Text("Preview Course")
                                .font(.headline)
                            Image(systemName: "eye")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            viewModel.newCourse.modules.isEmpty ?
                            Color.gray.opacity(0.3) :
                            AppTheme.primaryBlue
                        )
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.cornerRadius)
                        .shadow(color: viewModel.newCourse.modules.isEmpty ? .clear : AppTheme.primaryBlue.opacity(0.3), radius: 8, y: 4)
                    }
                    .disabled(viewModel.newCourse.modules.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(viewModel.newCourse.title)
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
    @State private var showContentTypeMenu = false
    @State private var selectedLessonForContent: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Module Header
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    // Expand/Collapse Button
                    Button(action: onToggleExpand) {
                        Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    // Title or TextField
                    VStack(alignment: .leading, spacing: 8) {
                        if isEditing {
                            TextField("Module Name", text: $editingTitle)
                                .font(.headline)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            Text(module.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // Show description if exists
                            if let desc = module.description, !desc.isEmpty {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        if isEditing {
                            Button(action: onEditEnd) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }
                        } else {
                            Button(action: onEditStart) {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                            }
                        }
                        
                        Button(action: { showDeleteAlert = true }) {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                    }
                }
                
                // Description field when editing
                if isEditing {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .topLeading) {
                            if editingDescription.isEmpty {
                                Text("Write description for this module...")
                                    .foregroundColor(.gray.opacity(0.6))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            
                            TextEditor(text: $editingDescription)
                                .frame(minHeight: 60)
                                .scrollContentBackground(.hidden)
                                .padding(4)
                        }
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                }
                
                // Lesson count
                if !isEditing {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.caption)
                        Text("\(module.lessons.count) Lessons")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            
            // Lessons Section (Expandable)
            if isExpanded && !isEditing {
                Divider()
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    // Lessons List
                    ForEach(module.lessons) { lesson in
                        LessonInlineRow(
                            lesson: lesson,
                            moduleID: module.id,
                            viewModel: viewModel,
                            showContentTypeMenu: $showContentTypeMenu,
                            selectedLessonForContent: $selectedLessonForContent
                        )
                    }
                    
                    // Add Lesson Button
                    if showingAddLessonFor == module.id {
                        HStack(spacing: 12) {
                            TextField("Lesson name", text: $newLessonName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: {
                                if !newLessonName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    viewModel.addLesson(to: module.id, title: newLessonName)
                                    newLessonName = ""
                                    showingAddLessonFor = nil
                                }
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }
                            
                            Button(action: {
                                newLessonName = ""
                                showingAddLessonFor = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title3)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    } else {
                        Button(action: {
                            showingAddLessonFor = module.id
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Lesson")
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        .alert("Delete Module", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete this module? This action cannot be undone.")
        }
    }
}

// MARK: - Lesson Inline Row

struct LessonInlineRow: View {
    let lesson: Lesson
    let moduleID: UUID
    @ObservedObject var viewModel: CourseCreationViewModel
    @Binding var showContentTypeMenu: Bool
    @Binding var selectedLessonForContent: UUID?
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Content Type Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: lesson.type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            }
            
            // Lesson Name
            Text(lesson.title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            // + Content Button
            Menu {
                ForEach(ContentType.allCases) { type in
                    Button(action: {
                        updateLessonContentType(to: type)
                    }) {
                        Label(type.rawValue, systemImage: type.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                    Text("Content")
                }
                .font(.caption.bold())
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Delete Button
            Button(action: { showDeleteAlert = true }) {
                Image(systemName: "trash.circle.fill")
                    .foregroundColor(.red)
                    .font(.body)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .cornerRadius(8)
        .padding(.horizontal)
        .alert("Delete Lesson", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let moduleIndex = viewModel.newCourse.modules.firstIndex(where: { $0.id == moduleID }),
                   let lessonIndex = viewModel.newCourse.modules[moduleIndex].lessons.firstIndex(where: { $0.id == lesson.id }) {
                    viewModel.deleteLesson(moduleID: moduleID, at: IndexSet(integer: lessonIndex))
                }
            }
        } message: {
            Text("Are you sure you want to delete this lesson?")
        }
    }
    
    private func updateLessonContentType(to type: ContentType) {
        var updatedLesson = lesson
        updatedLesson.type = type
        viewModel.updateLesson(moduleID: moduleID, lesson: updatedLesson)
    }
}

#Preview {
    NavigationView {
        CourseStructureView(viewModel: CourseCreationViewModel(educatorID: UUID()))
    }
}
