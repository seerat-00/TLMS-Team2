//
//  LessonContentEditorView.swift
//  TLMS-project-main
//
//  View for editing lesson content based on type (Text, Video, PDF, Presentation)
//

import SwiftUI

struct LessonContentEditorView: View {
    @ObservedObject var viewModel: CourseCreationViewModel
    let moduleID: UUID
    let lessonID: UUID
    @Environment(\.dismiss) var dismiss
    
    // State for content editing
    @State private var textContent: String = ""
    @State private var contentDescription: String = ""
    @State private var showFilePicker = false
    @State private var selectedFileURL: URL?
    @State private var selectedFileName: String?
    @State private var showSuccessAlert = false
    @State private var isUploading = false
    @State private var uploadError: String?
    
    @StateObject private var storageService = StorageService()
    
    // Derived binding to get the lesson
    private var lesson: Lesson? {
        guard let moduleIndex = viewModel.newCourse.modules.firstIndex(where: { $0.id == moduleID }),
              let lessonIndex = viewModel.newCourse.modules[moduleIndex].lessons.firstIndex(where: { $0.id == lessonID }) else {
            return nil
        }
        return viewModel.newCourse.modules[moduleIndex].lessons[lessonIndex]
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            if let currentLesson = lesson {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: currentLesson.type.icon)
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(currentLesson.title)
                                        .font(.title2.bold())
                                    
                                    Text(currentLesson.type.rawValue + " Content")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Content Editor based on type
                        switch currentLesson.type {
                        case .text:
                            TextContentEditor(textContent: $textContent)
                            
                        case .video:
                            MediaContentEditor(
                                contentType: .video,
                                description: $contentDescription,
                                selectedFileURL: $selectedFileURL,
                                selectedFileName: $selectedFileName,
                                showFilePicker: $showFilePicker
                            )
                            
                        case .pdf:
                            MediaContentEditor(
                                contentType: .pdf,
                                description: $contentDescription,
                                selectedFileURL: $selectedFileURL,
                                selectedFileName: $selectedFileName,
                                showFilePicker: $showFilePicker
                            )
                            
                        case .presentation:
                            MediaContentEditor(
                                contentType: .presentation,
                                description: $contentDescription,
                                selectedFileURL: $selectedFileURL,
                                selectedFileName: $selectedFileName,
                                showFilePicker: $showFilePicker
                            )
                            
                        case .quiz:
                            QuizPlaceholderView()
                        }
                        
                        // Save Button
                        Button(action: {
                            Task {
                                await saveContent()
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Content")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(canSave ? AppTheme.primaryBlue : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: canSave ? AppTheme.primaryBlue.opacity(0.3) : .clear, radius: 8, y: 4)
                        }
                        .disabled(!canSave)
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
                .onAppear {
                    loadExistingContent()
                }
                .alert("Content Saved", isPresented: $showSuccessAlert) {
                    Button("OK") {
                        dismiss()
                    }
                } message: {
                    Text("Your lesson content has been saved successfully.")
                }
            } else {
                Text("Lesson not found")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Edit Content")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFilePicker) {
            filePickerForType()
        }
        .overlay {
            if isUploading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Uploading file...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(AppTheme.primaryBlue)
                    .cornerRadius(20)
                }
            }
        }
        .alert("Upload Error", isPresented: .constant(uploadError != nil)) {
            Button("OK") {
                uploadError = nil
            }
        } message: {
            if let error = uploadError {
                Text(error)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadExistingContent() {
        guard let currentLesson = lesson else { return }
        
        switch currentLesson.type {
        case .text:
            textContent = currentLesson.textContent ?? ""
        case .video, .pdf, .presentation:
            contentDescription = currentLesson.contentDescription ?? ""
            selectedFileName = currentLesson.fileName
            if let urlString = currentLesson.fileURL {
                selectedFileURL = URL(string: urlString)
            }
        case .quiz:
            break
        }
    }
    
    private func saveContent() async {
        guard let moduleIndex = viewModel.newCourse.modules.firstIndex(where: { $0.id == moduleID }),
              let lessonIndex = viewModel.newCourse.modules[moduleIndex].lessons.firstIndex(where: { $0.id == lessonID }) else {
            return
        }
        
        var updatedLesson = viewModel.newCourse.modules[moduleIndex].lessons[lessonIndex]
        
        switch updatedLesson.type {
        case .text:
            updatedLesson.textContent = textContent
            
        case .video, .pdf, .presentation:
            updatedLesson.contentDescription = contentDescription
            updatedLesson.fileName = selectedFileName
            
            // Upload file to Supabase Storage if a new file is selected
            if let localURL = selectedFileURL {
                isUploading = true
                do {
                    // Upload to Supabase Storage and get public URL
                    let publicURL = try await storageService.uploadFile(
                        fileURL: localURL,
                        fileName: selectedFileName ?? "file"
                    )
                    updatedLesson.fileURL = publicURL
                    print("✅ File uploaded successfully: \(publicURL)")
                } catch {
                    isUploading = false
                    uploadError = "Failed to upload file: \(error.localizedDescription)"
                    print("❌ Upload error: \(error)")
                    return
                }
                isUploading = false
            }
            
        case .quiz:
            break
        }
        
        viewModel.updateLesson(moduleID: moduleID, lesson: updatedLesson)
        showSuccessAlert = true
    }
    
    private var canSave: Bool {
        guard let currentLesson = lesson else { return false }
        
        switch currentLesson.type {
        case .text:
            return !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .video, .pdf, .presentation:
            return selectedFileURL != nil && !contentDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .quiz:
            return false
        }
    }
    
    @ViewBuilder
    private func filePickerForType() -> some View {
        if let currentLesson = lesson {
            switch currentLesson.type {
            case .video:
                VideoPicker(selectedURL: $selectedFileURL, selectedFileName: $selectedFileName)
            case .pdf:
                PDFPicker(selectedURL: $selectedFileURL, selectedFileName: $selectedFileName)
            case .presentation:
                PresentationPicker(selectedURL: $selectedFileURL, selectedFileName: $selectedFileName)
            default:
                Text("Unsupported")
            }
        } else {
            Text("Error")
        }
    }
}

// MARK: - Text Content Editor

struct TextContentEditor: View {
    @Binding var textContent: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lesson Content")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Text("Write the text content for this lesson. You can include explanations, instructions, or any educational material.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ZStack(alignment: .topLeading) {
                if textContent.isEmpty {
                    Text("Start typing your lesson content here...\n\nYou can write multiple paragraphs, include examples, and format your text to make it easy for learners to understand.")
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                }
                
                TextEditor(text: $textContent)
                    .frame(minHeight: 300)
                    .scrollContentBackground(.hidden)
                    .padding(12)
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Media Content Editor (Video, PDF, Presentation)

struct MediaContentEditor: View {
    let contentType: ContentType
    @Binding var description: String
    @Binding var selectedFileURL: URL?
    @Binding var selectedFileName: String?
    @Binding var showFilePicker: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // File Upload Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Upload \(contentType.rawValue)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Button(action: { showFilePicker = true }) {
                    VStack(spacing: 16) {
                        if let fileName = selectedFileName {
                            // File selected
                            HStack(spacing: 12) {
                                Image(systemName: contentType.icon)
                                    .font(.system(size: 36))
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(fileName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("\(contentType.rawValue) Selected")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }
                            .padding()
                        } else {
                            // No file selected
                            VStack(spacing: 12) {
                                Image(systemName: "arrow.up.doc.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.blue)
                                
                                Text("Tap to select \(contentType.rawValue.lowercased()) file")
                                    .font(.headline)
                                
                                Text(uploadInstructions)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.vertical, 32)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        selectedFileName != nil ?
                        Color.green.opacity(0.05) :
                        Color.blue.opacity(0.05)
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedFileName != nil ? Color.green : Color.blue,
                                style: StrokeStyle(lineWidth: 2, dash: selectedFileName != nil ? [] : [5, 5])
                            )
                    )
                    .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
                
                if selectedFileName != nil {
                    Button(action: { 
                        selectedFileURL = nil
                        selectedFileName = nil
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Remove File")
                                .font(.subheadline.bold())
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
            
            // Description Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Text("Provide a brief description of this \(contentType.rawValue.lowercased()) content to help learners understand what they'll learn.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("E.g., 'This video explains the fundamental concepts of...'\n\nProvide context and key takeaways for learners.")
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                    }
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var uploadInstructions: String {
        switch contentType {
        case .video:
            return "Select a video file from your device (MP4, MOV, etc.)"
        case .pdf:
            return "Select a PDF document from your device"
        case .presentation:
            return "Select a Keynote or PowerPoint presentation"
        default:
            return "Select a file from your device"
        }
    }
}

// MARK: - Quiz Placeholder

struct QuizPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("Quiz Content")
                .font(.title2.bold())
            
            Text("Quiz questions are managed separately through the Quiz Editor.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationView {
        LessonContentEditorView(
            viewModel: CourseCreationViewModel(educatorID: UUID()),
            moduleID: UUID(),
            lessonID: UUID()
        )
    }
}
