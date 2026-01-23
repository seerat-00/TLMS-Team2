//
//  AdminCourseDetailView.swift
//  TLMS-project-main
//
//  View for Admin to review and approve/reject courses
//

import SwiftUI

struct AdminCourseDetailView: View {
    let course: Course
    @Environment(\.dismiss) var dismiss
    @StateObject private var courseService = CourseService()
    @StateObject private var authService = AuthService()
    @State private var isProcessing = false
    @State private var expandedModules: Set<UUID> = []
    @State private var educatorName: String = "Loading..."
    @State private var selectedLesson: Lesson?
    
    var onStatusChange: (() -> Void)?
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Premium Header (Matches Educator/Learner)
                    ZStack(alignment: .bottomLeading) {
                        let imageName = CourseImageHelper.getCourseImage(courseCoverUrl: course.courseCoverUrl, category: course.category)
                        
                        if let uiImage = UIImage(named: imageName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(minHeight: 200)
                                .clipped()
                        } else {
                            LinearGradient(
                                colors: [course.categoryColor.opacity(0.8), course.categoryColor.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(minHeight: 200)
                        }
                        
                        // Dark Overlay
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.8)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        .frame(minHeight: 200)
                        
                        // Title Overlay
                        VStack(alignment: .leading, spacing: 8) {
                            Text(course.category.uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(course.categoryColor.opacity(0.8))
                                .cornerRadius(4)
                            
                            Text(course.title)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                                .minimumScaleFactor(0.6)
                                .lineLimit(2)
                                .padding(.bottom, 20)
                        }
                        .padding(24)
                    }
                    .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                    .ignoresSafeArea(edges: .top)
                    
                    VStack(spacing: 24) {
                        // MARK: - Admin Metadata Card
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Submitted by Educator")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                    Text(educatorName)
                                        .font(.headline)
                                        .foregroundColor(AppTheme.primaryText)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Image(systemName: course.status.icon)
                                    Text(course.status.displayName)
                                }
                                .font(.caption.bold())
                                .foregroundColor(course.status.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(course.status.color.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Divider()
                            
                            // Stats Row
                            HStack(spacing: 20) {
                                Label(course.level.rawValue, systemImage: "chart.bar.fill")
                                Label("\(course.modules.count) Modules", systemImage: "book.fill")
                                Spacer()
                                if let price = course.price {
                                    Text(price == 0 ? "Free" : price.formatted(.currency(code: "INR")))
                                        .font(.headline)
                                        .foregroundColor(price == 0 ? AppTheme.successGreen : AppTheme.primaryBlue)
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryText)
                        }
                        .padding(24)
                        .background(AppTheme.secondaryGroupedBackground)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                        .padding(.top, -30) // Overlap the header
                        
                        // MARK: - Revenue Split Card
                        if let price = course.price, price > 0 {
                            let split = RevenueCalculator.calculateSplit(total: price)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Revenue Distribution")
                                        .font(.headline)
                                    Spacer()
                                    Text("Per Enrollment")
                                        .font(.caption.bold())
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                                
                                HStack(spacing: 20) {
                                    // Total
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Course Price")
                                            .font(.caption2.bold())
                                            .foregroundColor(AppTheme.secondaryText)
                                        Text(price.formatted(.currency(code: "INR")))
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(AppTheme.primaryText)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // Split
                                    HStack(spacing: 12) {
                                        VStack(alignment: .trailing, spacing: 6) {
                                            Text("Educator (80%)")
                                                .font(.caption2.bold())
                                                .foregroundColor(AppTheme.primaryBlue)
                                            Text(split.educator.formatted(.currency(code: "INR")))
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(AppTheme.primaryBlue)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                        
                                        Rectangle()
                                            .fill(Color.secondary.opacity(0.1))
                                            .frame(width: 1, height: 30)
                                        
                                        VStack(alignment: .trailing, spacing: 6) {
                                            Text("Platform (20%)")
                                                .font(.caption2.bold())
                                                .foregroundColor(.purple)
                                            Text(split.admin.formatted(.currency(code: "INR")))
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.purple)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                    }
                                }
                                .padding(16)
                                .background(AppTheme.cardBackground.opacity(0.5))
                                .cornerRadius(12)
                            }
                            .padding(20)
                            .background(AppTheme.secondaryGroupedBackground)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                        
                        // Content Preview
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Course Content")
                                    .font(.headline)
                                Spacer()
                                Text("\(course.modules.count) Modules")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal, 24)
                            
                            ForEach(Array(course.modules.enumerated()), id: \.element.id) { index, module in
                                ModulePreviewCard(
                                    module: module,
                                    moduleNumber: index + 1,
                                    isExpanded: expandedModules.contains(module.id),
                                    isEnrolled: true,
                                    onToggle: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if expandedModules.contains(module.id) {
                                                expandedModules.remove(module.id)
                                            } else {
                                                expandedModules.insert(module.id)
                                            }
                                        }
                                    },
                                    onLessonTap: { lesson in
                                        selectedLesson = lesson
                                    }
                                )
                            }
                        }
                        .padding(.top, 8)
                        
                        // MARK: - Action Toolbar
                        HStack(spacing: 16) {
                            Button(action: rejectCourse) {
                                HStack {
                                    if isProcessing {
                                        ProgressView()
                                    } else {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("Reject")
                                            .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(14)
                            }
                            .disabled(isProcessing)
                            
                            Button(action: approveCourse) {
                                HStack {
                                    if isProcessing {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "checkmark.seal.fill")
                                        Text("Approve Course")
                                            .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppTheme.primaryBlue)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                                .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 8, y: 4)
                            }
                            .disabled(isProcessing)
                        }
                        .padding(24)
                        .padding(.bottom, 20)
                    }
                }
                .padding(.top)
            }
        }
        .background(AppTheme.groupedBackground)
        .navigationTitle("Review Course")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedLesson) { lesson in
            LessonContentView(
                lesson: lesson,
                course: course,
                userId: UUID(), // Admin preview doesn't need progress tracking
                selectedLesson: $selectedLesson,
                isPreviewMode: true  // Hide completion button for admin
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            await fetchEducatorName()
        }
    }
    
    // MARK: - Data Loading
    
    private func fetchEducatorName() async {
        if let educator = await authService.fetchUserById(course.educatorID) {
            educatorName = educator.fullName
        } else {
            educatorName = "Unknown Educator"
        }
    }
    
    // MARK: - Actions
    
    private func approveCourse() {
        Task {
            isProcessing = true
            let success = await courseService.updateCourseStatus(courseID: course.id, status: .published)
            isProcessing = false
            if success {
                onStatusChange?()
                dismiss()
            }
        }
    }
    
    private func rejectCourse() {
        Task {
            isProcessing = true
            let success = await courseService.updateCourseStatus(courseID: course.id, status: .rejected)
            isProcessing = false
            if success {
                onStatusChange?()
                dismiss()
            }
        }
    }
}
