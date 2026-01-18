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
                        // Header
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Course")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                    Text(course.category)
                                        .font(.subheadline.bold())
                                        .foregroundColor(AppTheme.primaryBlue)
                                        .lineLimit(1)
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
                                } else if isPaidCourse {
                                    // Show price badge
                                    if let price = course.price {
                                        Text(price.formatted(.currency(code: "INR")))
                                            .font(.title3.bold())
                                            .foregroundColor(AppTheme.primaryBlue)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(AppTheme.primaryBlue.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            Text(course.title)
                                .font(.title2.bold())
                                .foregroundColor(AppTheme.primaryText)
                            
                            Text(course.description)
                                .font(.body)
                                .foregroundColor(AppTheme.secondaryText)
                            
                            // Metadata
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
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .padding(.horizontal)
                        
                        // Content Preview
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Course Content")
                                .font(.title3.bold())
                                .foregroundColor(AppTheme.primaryText)
                                .padding(.horizontal)
                            
                            if course.modules.isEmpty {
                                Text("No content available yet.")
                                    .font(.subheadline)
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
                        
                        Spacer(minLength: 80) // Space for bottom bar
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
                enrollmentBottomBar
            }
        }
        .sheet(isPresented: $showPaymentSheet) {
            if let url = paymentURL {
                PaymentWebView(
                    paymentURL: url,
                    onSuccess: { paymentId in
                        Task {
                            await handlePaymentSuccess(paymentId: paymentId)
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
    
    // MARK: - Enrollment Bottom Bar
    
    private var enrollmentBottomBar: some View {
        VStack {
            Divider()
            HStack {
                Button(action: handleEnrollmentAction) {
                    HStack {
                        if isEnrolling || paymentService.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            if isPaidCourse, let price = course.price {
                                HStack(spacing: 8) {
                                    Image(systemName: "cart.fill")
                                    Text("Buy Now - \(price.formatted(.currency(code: "INR")))")
                                }
                                .font(.headline)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Enroll Free")
                                }
                                .font(.headline)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primaryBlue)
                    .foregroundColor(.white)
                    .cornerRadius(AppTheme.cornerRadius)
                }
                .disabled(isEnrolling || paymentService.isLoading)
            }
            .padding()
            .background(AppTheme.secondaryGroupedBackground)
        }
    }
    
    // MARK: - Actions
    
    private func handleEnrollmentAction() {
        if isPaidCourse {
            // Initiate payment
            Task {
                await initiatePayment()
            }
        } else {
            // Free enrollment
            Task {
                isEnrolling = true
                await onEnroll()
                isEnrolling = false
                dismiss()
            }
        }
    }
    
    private func initiatePayment() async {
        guard let price = course.price else { return }
        guard let user = authService.currentUser else { return }
        
        // Create payment order
        if let order = await paymentService.createPaymentOrder(
            courseId: course.id,
            userId: userId,
            amount: price
        ) {
            // Save the order ID for verification
            self.currentOrderId = order.orderId
            
            // Generate payment URL
            if let url = paymentService.getPaymentURL(
                order: order,
                userEmail: user.email,
                userName: user.fullName
            ) {
                paymentURL = url
                showPaymentSheet = true
            } else {
                errorMessage = "Failed to generate payment link"
                showError = true
            }
        } else {
            errorMessage = paymentService.errorMessage ?? "Failed to create payment order"
            showError = true
        }
    }
    
    private func handlePaymentSuccess(paymentId: String) async {
        // Verify payment and enroll
        guard let orderId = currentOrderId else {
            errorMessage = "Order ID validation failed"
            showError = true
            return
        }
        
        let success = await paymentService.verifyPayment(
            orderId: orderId,
            paymentId: paymentId,
            courseId: course.id,
            userId: userId
        )
        
        if success {
            // User is already enrolled by verifyPayment, just dismiss
            dismiss()
        } else {
            errorMessage = paymentService.errorMessage ?? "Payment verification failed"
            showError = true
        }
    }
}

