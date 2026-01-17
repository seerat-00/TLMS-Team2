
//
//  LearnerCourseDetailView.swift
//  TLMS-project-main
//
//  View for Learners to preview course content and enroll
//

import SwiftUI

struct LearnerCourseDetailView: View {
    let course: Course
    let isEnrolled: Bool
    let userId: UUID
    var onEnroll: () async -> Void
    
    @State private var expandedModules: Set<UUID> = []
    @State private var isEnrolling = false
    @State private var showPaymentSheet = false
    @State private var paymentURL: URL?
    @State private var currentOrderId: String?
    @State private var showError = false
    @State private var errorMessage = ""
    
    @StateObject private var paymentService = PaymentService()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    var isPaidCourse: Bool {
        if let price = course.price, price > 0 {
            return true
        }
        return false
    }
    
    var body: some View {
        Group {
            if course.status != .published {
                CourseNotAvailableView()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MARK: - Header
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Course")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                    
                                    Text(course.category)
                                        .font(.subheadline.bold())
                                        .foregroundColor(AppTheme.primaryBlue)
                                }
                                
                                Spacer()
                                
                                if isEnrolled {
                                    Label("Enrolled", systemImage: "checkmark.circle.fill")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(AppTheme.successGreen.opacity(0.1))
                                        .foregroundColor(AppTheme.successGreen)
                                        .cornerRadius(8)
                                } else if isPaidCourse, let price = course.price {
                                    Text(price.formatted(.currency(code: "INR")))
                                        .font(.title3.bold())
                                        .foregroundColor(AppTheme.primaryBlue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(AppTheme.primaryBlue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            
                            Divider()
                            
                            Text(course.title)
                                .font(.title2.bold())
                            
                            Text(course.description)
                                .font(.body)
                                .foregroundColor(AppTheme.secondaryText)
                            
                            HStack(spacing: 16) {
                                Label("\(course.modules.count) Modules", systemImage: "book.fill")
                                
                                if let enrolledCount = course.enrolledCount {
                                    Label("\(enrolledCount) Students", systemImage: "person.2.fill")
                                }
                                
                                if let rating = course.rating {
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.orange)
                                        Text(String(format: "%.1f", rating))
                                    }
                                }
                            }
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        }
                        .padding()
                        .background(AppTheme.secondaryGroupedBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // MARK: - Course Content
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Course Content")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            if course.modules.isEmpty {
                                Text("No content available yet.")
                                    .foregroundColor(AppTheme.secondaryText)
                                    .padding(.horizontal)
                            } else {
                                ForEach(Array(course.modules.enumerated()), id: \.element.id) { index, module in
                                    ModulePreviewCard(
                                        module: module,
                                        moduleNumber: index + 1,
                                        isExpanded: expandedModules.contains(module.id),
                                        onToggle: {
                                            withAnimation {
                                                if expandedModules.contains(module.id) {
                                                    expandedModules.remove(module.id)
                                                } else {
                                                    expandedModules.insert(module.id)
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.top)
                }
            }
        }
        .background(AppTheme.groupedBackground)
        .navigationTitle("Course Details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !isEnrolled {
                CourseEnrollmentBottomBar(
                    course: course,
                    isPaidCourse: isPaidCourse,
                    isEnrolling: isEnrolling,
                    isLoading: paymentService.isLoading,
                    onAction: handleEnrollmentAction
                )
            }
        }
        .sheet(isPresented: $showPaymentSheet) {
            if let url = paymentURL {
                PaymentWebView(
                    paymentURL: url,
                    onSuccess: { paymentId in
                        Task {
                            await CoursePaymentHandler.verifyPayment(
                                orderId: currentOrderId ?? "",
                                paymentId: paymentId,
                                course: course,
                                userId: userId,
                                paymentService: paymentService,
                                onSuccess: {
                                    dismiss()
                                },
                                onError: {
                                    errorMessage = $0
                                    showError = true
                                }
                            )
                        }
                    },
                    onFailure: {
                        errorMessage = "Payment was cancelled or failed"
                        showError = true
                    }
                )
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Actions
    
    private func handleEnrollmentAction() {
        if isPaidCourse {
            Task {
                await CoursePaymentHandler.initiatePayment(
                    course: course,
                    userId: userId,
                    authService: authService,
                    paymentService: paymentService,
                    setOrderId: { currentOrderId = $0 },
                    setPaymentURL: {
                        paymentURL = $0
                        showPaymentSheet = true
                    },
                    onError: {
                        errorMessage = $0
                        showError = true
                    }
                )
            }
        } else {
            Task {
                isEnrolling = true
                await onEnroll()
                isEnrolling = false
                dismiss()
            }
        }
    }
}
