import SwiftUI
import PDFKit
import AVKit
import WebKit

/// Educator view to preview published courses and their content
struct EducatorCoursePreviewView: View {
    let courseId: UUID
    @StateObject private var courseService = CourseService()
    @State private var course: Course?
    @State private var isLoading = true
    @State private var expandedModules: Set<UUID> = []
    @State private var selectedLesson: Lesson?
    @State private var showLessonContent = false
    @State private var selectedTab = 0 // 0 = Content, 1 = Reviews
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.groupedBackground
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView("Loading course...")
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryAccent))
            } else if let course = course {
                VStack(spacing: 0) {
                    // Course Header (Fixed, non-scrollable)
                    courseHeaderView(course: course)
                    
                    // Tab Selector
                    HStack(spacing: 0) {
                        TabButton(title: "Content", isSelected: selectedTab == 0) {
                            selectedTab = 0
                        }
                        
                        TabButton(title: "Reviews", isSelected: selectedTab == 1) {
                            selectedTab = 1
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .background(AppTheme.groupedBackground)
                    
                    // Tab Content (Scrollable)
                    if selectedTab == 0 {
                        // Course Content Tab
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Course Content")
                                    .font(.title2.bold())
                                    .foregroundColor(AppTheme.primaryText)
                                    .padding(.horizontal)
                                    .padding(.top)
                                
                                ForEach(Array(course.modules.enumerated()), id: \.element.id) { index, module in
                                    ModulePreviewCard(
                                        module: module,
                                        moduleNumber: index + 1,
                                        isExpanded: expandedModules.contains(module.id),
                                        isEnrolled: true,
                                        onToggle: {
                                            if expandedModules.contains(module.id) {
                                                expandedModules.remove(module.id)
                                            } else {
                                                expandedModules.insert(module.id)
                                            }
                                        },
                                        onLessonTap: { lesson in
                                            selectedLesson = lesson
                                            showLessonContent = true
                                        }
                                    )
                                }
                            }
                            .padding(.bottom, 40)
                        }
                    } else {
                        // Reviews Tab
                        EducatorCourseReviewsView(courseID: course.id)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(AppTheme.secondaryText)
                    Text("Course not found")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                }
            }
        }
        .navigationTitle("Course Preview")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCourse()
        }
        .sheet(isPresented: $showLessonContent) {
            if let lesson = selectedLesson, let course = course {
                NavigationView {
                    EducatorLessonContentView(lesson: lesson, course: course)
                }
            }
        }
    }
    
    private func courseHeaderView(course: Course) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Course cover image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(course.categoryColor.opacity(0.2))
                    .frame(height: 180)
                
                VStack(spacing: 12) {
                    Image(systemName: course.categoryIcon)
                        .font(.system(size: 50))
                        .foregroundColor(course.categoryColor)
                    
                    Text(course.category)
                        .font(.headline)
                        .foregroundColor(course.categoryColor)
                }
            }
            
            // Course title and description
            VStack(alignment: .leading, spacing: 12) {
                Text(course.title)
                    .font(.title.bold())
                    .foregroundColor(AppTheme.primaryText)
                
                Text(course.description)
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Course metadata
                HStack(spacing: 16) {
//                    Label(course.level.rawValue, systemImage: "chart.bar.fill")
//                        .font(.subheadline)
//                        .foregroundColor(AppTheme.secondaryText)
                    
                    if let price = course.price {
                        Label("₹\(String(format: "%.2f", price))", systemImage: "rupee.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.successGreen)
                    } else {
                        Label("Free", systemImage: "gift.fill")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.successGreen)
                    }
                    
                    Label("\(course.enrollmentCount) enrolled", systemImage: "person.2.fill")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: course.status.icon)
                        .font(.caption)
                    Text(course.status.displayName)
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(course.status.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(course.status.color.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
        .padding(.top)
    }
    
    private func loadCourse() async {
        isLoading = true
        course = await courseService.fetchCourse(by: courseId)
        isLoading = false
    }
}

/// Educator-specific lesson content viewer (read-only, no completion tracking)
struct EducatorLessonContentView: View {
    let lesson: Lesson
    let course: Course
    @Environment(\.dismiss) var dismiss
    @State private var showTranscript = true
    @State private var transcriptFileURL: URL?
    
    var body: some View {
        ZStack {
            AppTheme.groupedBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerView
                    
                    // Content
                    contentView
                }
                .padding()
            }
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: lesson.type.icon)
                    .font(.title3)
                    .foregroundColor(AppTheme.primaryAccent)
                
                Text(lesson.type.rawValue)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.primaryAccent.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
            }
            
            Text(lesson.title)
                .font(.title2.bold())
                .foregroundColor(AppTheme.primaryText)
            
            if let description = lesson.contentDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding()
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch lesson.type {
        case .text:
            if let text = lesson.textContent, !text.isEmpty {
                Text(text)
                    .font(.body)
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(6)
                    .padding()
                    .background(AppTheme.secondaryGroupedBackground)
                    .cornerRadius(AppTheme.cornerRadius)
            } else {
                EmptyContentView(message: "No text content available.")
            }
            
        case .video:
            videoContentView
            
        case .pdf:
            if let urlStr = lesson.fileURL, let url = URL(string: urlStr) {
                DocumentViewer(url: url, fileName: lesson.fileName ?? "Document.pdf", documentType: .pdf)
            } else {
                EmptyContentView(message: "PDF not available.")
            }
            
        case .presentation:
            if let urlStr = lesson.fileURL, let url = URL(string: urlStr) {
                DocumentViewer(url: url, fileName: lesson.fileName ?? "Presentation", documentType: .powerpoint)
            } else {
                EmptyContentView(message: "Presentation not available.")
            }
            
        case .quiz:
            quizPreviewView
        }
    }
    
    private var videoContentView: some View {
        Group {
            if let urlStr = lesson.fileURL, let url = URL(string: urlStr) {
                VStack(spacing: 16) {
                    // Video Player
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(height: 250)
                        .cornerRadius(AppTheme.cornerRadius)
                    
                    // About section
                    if let desc = lesson.contentDescription {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About this video")
                                .font(.headline)
                            
                            Text(desc)
                                .font(.body)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.secondaryGroupedBackground)
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                    
                    // Transcript Section
                    if let transcript = lesson.transcript, !transcript.isEmpty {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Transcript")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button {
                                    transcriptFileURL = createTranscriptFile(from: transcript)
                                } label: {
                                    Image(systemName: "arrow.down.doc")
                                }
                                
                                if let fileURL = transcriptFileURL {
                                    ShareLink(item: fileURL) {
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                }
                                
                                Button(showTranscript ? "Hide" : "Show") {
                                    showTranscript.toggle()
                                }
                                .foregroundColor(AppTheme.primaryBlue)
                            }
                            
                            if showTranscript {
                                ScrollView {
                                    Text(transcript)
                                        .lineSpacing(6)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxHeight: 250)
                            }
                        }
                        .padding()
                        .background(AppTheme.secondaryGroupedBackground)
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                }
            } else {
                EmptyContentView(message: "Invalid video URL.")
            }
        }
    }
    
    private var quizPreviewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.badge.questionmark.fill")
                    .font(.title)
                    .foregroundColor(AppTheme.primaryBlue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quiz")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    
                    if let timeLimit = lesson.quizTimeLimit {
                        Text("Time limit: \(timeLimit) minutes")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    if let passingScore = lesson.quizPassingScore {
                        Text("Passing score: \(passingScore)%")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(AppTheme.secondaryGroupedBackground)
            .cornerRadius(AppTheme.cornerRadius)
            
            // Quiz questions preview
            if let questions = lesson.quizQuestions, !questions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Questions (\(questions.count))")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    
                    ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                        EducatorQuestionPreviewCard(question: question, questionNumber: index + 1)
                    }
                }
            } else {
                EmptyContentView(message: "No questions added to this quiz.")
            }
        }
    }
    
    private func createTranscriptFile(from text: String) -> URL? {
        let safeTitle = lesson.title
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
        
        let fileName = "\(safeTitle)_Transcript.txt"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("❌ Failed to create transcript file:", error)
            return nil
        }
    }
}

// MARK: - Educator Question Preview Card (renamed to avoid conflict)

struct EducatorQuestionPreviewCard: View {
    let question: Question
    let questionNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question header
            HStack {
                Text("Question \(questionNumber)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.primaryBlue)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: question.type.icon)
                        .font(.caption2)
                    Text(question.type.displayName)
                        .font(.caption2)
                }
                .foregroundColor(AppTheme.secondaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.secondaryText.opacity(0.1))
                .cornerRadius(6)
                
                Text("\(question.points) pts")
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppTheme.successGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.successGreen.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Question text
            Text(question.text)
                .font(.body)
                .foregroundColor(AppTheme.primaryText)
            
            // Options or character limit
            if question.type == .descriptive {
                HStack {
                    Image(systemName: "text.alignleft")
                        .font(.caption)
                    Text("Text answer (max \(question.characterLimit) characters)")
                        .font(.caption)
                }
                .foregroundColor(AppTheme.secondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.secondaryText.opacity(0.1))
                .cornerRadius(6)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                        HStack(spacing: 12) {
                            Image(systemName: question.correctAnswerIndices.contains(index) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(question.correctAnswerIndices.contains(index) ? AppTheme.successGreen : AppTheme.secondaryText)
                            
                            Text(option)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.primaryText)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(question.correctAnswerIndices.contains(index) ? AppTheme.successGreen.opacity(0.1) : AppTheme.secondaryGroupedBackground)
                        .cornerRadius(8)
                    }
                }
            }
            
            // Explanation if available
            if let explanation = question.explanation, !explanation.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Explanation:")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.primaryBlue)
                    
                    Text(explanation)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding(12)
                .background(AppTheme.primaryBlue.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppTheme.primaryBlue : AppTheme.secondaryText)
                
                Rectangle()
                    .fill(isSelected ? AppTheme.primaryBlue : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
