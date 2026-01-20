//
//  LessonContentView.swift
//  TLMS-project-main
//
//  Comprehensive content viewer for all lesson types (video, PDF, text, presentation)
//

import SwiftUI
import PDFKit
import AVKit
import WebKit

struct LessonContentView: View {
    let lesson: Lesson
    let courseId: UUID
    let userId: UUID
    
    @State private var isCompleted = false
    @State private var showCompletionAlert = false
    @StateObject private var courseService = CourseService()
    @State private var isCheckingCompletion = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Header
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
                        
                        if isCompleted {
                            Label("Completed", systemImage: "checkmark.circle.fill")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppTheme.successGreen.opacity(0.1))
                                .foregroundColor(AppTheme.successGreen)
                                .cornerRadius(8)
                        }
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
                
                // MARK: - Content Display
                contentView
                
                // MARK: - Mark as Complete Button
                if !isCompleted {
                    Button(action: markAsComplete) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark as Complete")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .background(AppTheme.groupedBackground)
        .navigationTitle("Lesson")
        .navigationBarTitleDisplayMode(.inline)
        .task {
                   await checkIfAlreadyCompleted()
               }
        .alert("Lesson Complete!", isPresented: $showCompletionAlert) {
            Button("Continue", role: .cancel) {}
        } message: {
            Text("Great job! You've completed this lesson.")
        }
        .onAppear {
            loadCompletionStatus()
        }
    }
    
    // MARK: - Load Completion Status
    private func loadCompletionStatus() {
        Task {
            isCompleted = await courseService.isLessonCompleted(
                userId: userId,
                courseId: courseId,
                lessonId: lesson.id
            )
        }
    }
    // MARK: - Check if Completed (NEW ✅)
       private func checkIfAlreadyCompleted() async {
           isCheckingCompletion = true
           defer { isCheckingCompletion = false }

           let completed = await courseService.isLessonCompleted(
               userId: userId,
               courseId: courseId,
               lessonId: lesson.id
           )

           isCompleted = completed
       }
    
    // MARK: - Content View based on Type
    @ViewBuilder
    private var contentView: some View {
        switch lesson.type {
        case .text:
            textContentView
        case .video:
            videoContentView
        case .pdf:
            pdfContentView
        case .presentation:
            presentationContentView
        case .quiz:
            Text("Quizzes are handled separately")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .padding()
        }
    }
    
    // MARK: - Text Content
    @ViewBuilder
    private var textContentView: some View {
        if let textContent = lesson.textContent, !textContent.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(textContent)
                    .font(.body)
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(6)
            }
            .padding()
            .background(AppTheme.secondaryGroupedBackground)
            .cornerRadius(AppTheme.cornerRadius)
        } else {
            EmptyContentView(message: "No text content available for this lesson.")
        }
    }
    
    // MARK: - Video Content
    @ViewBuilder
    private var videoContentView: some View {
        if let fileURL = lesson.fileURL, let url = URL(string: fileURL) {
            VStack(spacing: 16) {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 250)
                    .cornerRadius(AppTheme.cornerRadius)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                if let description = lesson.contentDescription {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About this video")
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text(description)
                            .font(.body)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.secondaryGroupedBackground)
                    .cornerRadius(AppTheme.cornerRadius)
                }
            }
        } else {
            EmptyContentView(message: "Video content is not available or the URL is invalid.")
        }
    }
    
    // MARK: - PDF Content
    @ViewBuilder
    private var pdfContentView: some View {
        if let fileURL = lesson.fileURL, let url = URL(string: fileURL) {
            DocumentViewer(
                url: url,
                fileName: lesson.fileName ?? "Document.pdf",
                documentType: .pdf
            )
        } else {
            EmptyContentView(message: "PDF document is not available or the URL is invalid.")
        }
    }
    
    // MARK: - Presentation Content
    @ViewBuilder
    private var presentationContentView: some View {
        if let fileURL = lesson.fileURL, let url = URL(string: fileURL) {
            DocumentViewer(
                url: url,
                fileName: lesson.fileName ?? "Presentation",
                documentType: .powerpoint
            )
        } else {
            EmptyContentView(message: "Presentation file is not available or the URL is invalid.")
        }
    }
    
    // MARK: - Actions
    private func markAsComplete() {
        Task {
            let success = await courseService.markLessonComplete(
                userId: userId,
                courseId: courseId,
                lessonId: lesson.id
            )
            
            if success {
                withAnimation {
                    isCompleted = true
                }
                showCompletionAlert = true
                
                // Update overall course progress
                await courseService.updateCourseProgress(
                    userId: userId,
                    courseId: courseId
                )
            }
        }
    }
}

// MARK: - Empty Content View
struct EmptyContentView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.secondaryText.opacity(0.6))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
}

// MARK: - PDF View Representable
struct PDFViewRepresentable: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        // Load PDF from URL
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update if needed
    }
}

// MARK: - Web View Representable (for presentations and other web content)
struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Update if needed
    }
}
