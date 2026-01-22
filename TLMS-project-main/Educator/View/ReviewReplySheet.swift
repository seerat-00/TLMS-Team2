//
//  ReviewReplySheet.swift
//  TLMS-project-main
//
//  Bottom sheet for educators to reply to reviews
//

import SwiftUI

struct ReviewReplySheet: View {
    let review: CourseReview
    let educatorID: UUID
    let onSubmit: (String) async -> Bool
    @Environment(\.dismiss) var dismiss
    
    @State private var replyText = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let maxCharacters = 500
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Original review preview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Replying to:")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AppTheme.secondaryText)
                                .textCase(.uppercase)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(review.reviewerName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(AppTheme.primaryText)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 2) {
                                        ForEach(1...5, id: \.self) { index in
                                            Image(systemName: index <= review.rating ? "star.fill" : "star")
                                                .font(.caption2)
                                                .foregroundColor(index <= review.rating ? .orange : .gray.opacity(0.3))
                                        }
                                    }
                                }
                                
                                if let reviewText = review.reviewText, !reviewText.isEmpty {
                                    Text(reviewText)
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.secondaryText)
                                        .lineLimit(3)
                                }
                            }
                            .padding(12)
                            .background(AppTheme.secondaryGroupedBackground)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Reply text editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Response")
                                .font(.headline)
                                .foregroundColor(AppTheme.primaryText)
                            
                            ZStack(alignment: .topLeading) {
                                if replyText.isEmpty {
                                    Text("Write a thoughtful response to this review...")
                                        .font(.body)
                                        .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 12)
                                }
                                
                                TextEditor(text: $replyText)
                                    .font(.body)
                                    .foregroundColor(AppTheme.primaryText)
                                    .frame(minHeight: 150)
                                    .scrollContentBackground(.hidden)
                                    .padding(4)
                            }
                            .background(AppTheme.secondaryGroupedBackground)
                            .cornerRadius(8)
                            
                            HStack {
                                Text("\(replyText.count)/\(maxCharacters)")
                                    .font(.caption)
                                    .foregroundColor(replyText.count > maxCharacters ? .red : AppTheme.secondaryText)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        
                        // Submit button
                        Button(action: handleSubmit) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Send Reply")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(canSubmit ? AppTheme.primaryBlue : AppTheme.secondaryText.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(AppTheme.cornerRadius)
                        }
                        .disabled(!canSubmit || isSubmitting)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("Reply to Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var canSubmit: Bool {
        !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        replyText.count <= maxCharacters
    }
    
    private func handleSubmit() {
        Task {
            isSubmitting = true
            let success = await onSubmit(replyText)
            isSubmitting = false
            
            if success {
                dismiss()
            } else {
                errorMessage = "Failed to submit reply. Please try again."
                showError = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ReviewReplySheet(
        review: CourseReview(
            id: UUID(),
            courseID: UUID(),
            userID: UUID(),
            rating: 4,
            reviewText: "Great course! Would love to see more advanced topics covered.",
            isVisible: true,
            createdAt: Date()
        ),
        educatorID: UUID(),
        onSubmit: { _ in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return true
        }
    )
}
