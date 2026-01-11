//
//  ModuleDetailView.swift
//  TLMS-project-main
//
//  Step 3: Module Details & Lessons
//

import SwiftUI

struct ModuleDetailView: View {
    @ObservedObject var viewModel: CourseCreationViewModel
    let moduleID: UUID
    
    @State private var isEditingTitle = false
    @State private var showingAddLessonAlert = false
    @State private var newLessonName = ""
    
    var moduleIndex: Int? {
        viewModel.newCourse.modules.firstIndex(where: { $0.id == moduleID })
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            if let index = moduleIndex {
                ScrollView {
                    VStack(spacing: 24) {
                        // Module Title Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Module Title")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField("Module Name", text: $viewModel.newCourse.modules[index].title)
                                    .font(.title3.bold())
                                    .padding(.vertical, 8)
                                    .disabled(!isEditingTitle)
                                
                                Button(action: {
                                    isEditingTitle.toggle()
                                }) {
                                    Image(systemName: isEditingTitle ? "checkmark.circle.fill" : "pencil.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(isEditingTitle ? .green : .blue)
                                }
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            
                            if isEditingTitle {
                                Text("Edit name to update specifically")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Module Description Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Module Description (Optional)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ZStack(alignment: .topLeading) {
                                if let desc = viewModel.newCourse.modules[index].description, desc.isEmpty || viewModel.newCourse.modules[index].description == nil {
                                    Text("Describe what this module covers...")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                }
                                
                                TextEditor(text: Binding(
                                    get: { viewModel.newCourse.modules[index].description ?? "" },
                                    set: { viewModel.newCourse.modules[index].description = $0 }
                                ))
                                .frame(minHeight: 80)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Lessons List
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Lessons")
                                    .font(.title2.bold())
                                
                                Spacer()
                                
                                Button(action: {
                                    newLessonName = ""
                                    showingAddLessonAlert = true
                                }) {
                                    Label("Add Lesson", systemImage: "plus")
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                            
                            if viewModel.newCourse.modules[index].lessons.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "doc.text.image")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("No Lessons Yet")
                                        .font(.headline)
                                    Text("Tap 'Add Lesson' to create your first lesson.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            } else {
                                ForEach(viewModel.newCourse.modules[index].lessons) { lesson in
                                    NavigationLink(destination: LessonDetailView(viewModel: viewModel, moduleID: moduleID, lessonID: lesson.id)) {
                                        LessonRow(lesson: lesson) {
                                            if let lessonIndex = viewModel.newCourse.modules[index].lessons.firstIndex(where: { $0.id == lesson.id }) {
                                                viewModel.deleteLesson(moduleID: moduleID, at: IndexSet(integer: lessonIndex))
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle()) // Important for list items
                                }
                                .onMove { source, destination in
                                    viewModel.moveLesson(moduleID: moduleID, from: source, to: destination)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            } else {
                Text("Module not found")
            }
        }
        .navigationTitle("Module Details")
        .alert("New Lesson", isPresented: $showingAddLessonAlert) {
            TextField("Lesson Name", text: $newLessonName)
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                if !newLessonName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    viewModel.addLesson(to: moduleID, title: newLessonName)
                }
            }
        } message: {
            Text("Enter a name for the new lesson.")
        }
    }
}

// MARK: - Subviews

struct LessonRow: View {
    let lesson: Lesson
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: lesson.type.icon)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(lesson.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
