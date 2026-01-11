//
//  LessonDetailView.swift
//  TLMS-project-main
//
//  Step 4: Lesson Configuration
//

import SwiftUI

struct LessonDetailView: View {
    @ObservedObject var viewModel: CourseCreationViewModel
    let moduleID: UUID
    let lessonID: UUID
    
    // Derived bindings to edit the model directly
    private var lessonBinding: Binding<Lesson>? {
        guard let moduleIndex = viewModel.newCourse.modules.firstIndex(where: { $0.id == moduleID }),
              let lessonIndex = viewModel.newCourse.modules[moduleIndex].lessons.firstIndex(where: { $0.id == lessonID }) else {
            return nil
        }
        return Binding(
            get: { viewModel.newCourse.modules[moduleIndex].lessons[lessonIndex] },
            set: { viewModel.newCourse.modules[moduleIndex].lessons[lessonIndex] = $0 }
        )
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            if let lesson = lessonBinding {
                ScrollView {
                    VStack(spacing: 24) {
                        // Title Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Lesson Title")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter lesson title", text: lesson.title)
                                .font(.title3)
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Description Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Lesson Description (Optional)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ZStack(alignment: .topLeading) {
                                if lesson.content.wrappedValue?.isEmpty ?? true {
                                    Text("Describe what learners will learn in this lesson...")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                }
                                
                                TextEditor(text: Binding(
                                    get: { lesson.content.wrappedValue ?? "" },
                                    set: { lesson.content.wrappedValue = $0 }
                                ))
                                .frame(minHeight: 100)
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
                        
                        // Content Type Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Content Type")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            Text("Choose the format for this lesson")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(ContentType.allCases) { type in
                                    ContentTypeSelectionCard(
                                        type: type,
                                        isSelected: lesson.type.wrappedValue == type,
                                        action: { lesson.type.wrappedValue = type }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .padding(.bottom, 30)
                }
                .navigationTitle("Edit Lesson")
            } else {
                Text("Lesson not found")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Content Type Selection Card

struct ContentTypeSelectionCard: View {
    let type: ContentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isSelected ?
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color.blue.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : .blue)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .background(
                isSelected ?
                Color.blue.opacity(0.05) :
                Color.clear
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.2) : Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ContentType Extension

extension ContentType {
    var description: String {
        switch self {
        case .video: return "Video content"
        case .pdf: return "PDF document"
        case .text: return "Text-based content"
        case .presentation: return "Slide presentation"
        case .quiz: return "Interactive quiz"
        }
    }
}

#Preview {
    NavigationView {
        LessonDetailView(
            viewModel: CourseCreationViewModel(educatorID: UUID()),
            moduleID: UUID(),
            lessonID: UUID()
        )
    }
}
