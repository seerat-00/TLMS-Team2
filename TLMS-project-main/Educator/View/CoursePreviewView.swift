import SwiftUI

struct CoursePreviewView: View {
    @ObservedObject var viewModel: CourseCreationViewModel
    @StateObject private var courseService = CourseService()
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    @State private var expandedModules: Set<UUID> = []
    @State private var showSuccessBanner = false
    @State private var successMessage = ""
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            // Professional background
            AppTheme.groupedBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Course Info Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text(viewModel.newCourse.title)
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text(viewModel.newCourse.description)
                            .font(.body)
                            .foregroundColor(AppTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "folder.fill")
                                .font(.caption)
                            Text(viewModel.newCourse.category)
                                .font(.subheadline)
                        }
                        .foregroundColor(AppTheme.primaryBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.primaryBlue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.secondaryGroupedBackground)
                    .cornerRadius(AppTheme.cornerRadius)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Course Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Course Content")
                            .font(.title2.bold())
                            .padding(.horizontal)
                        
                        ForEach(Array(viewModel.newCourse.modules.enumerated()), id: \.element.id) { index, module in
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
                                onLessonTap: { _ in }
                            )
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        // Save as Draft Button
                        Button(action: {
                            handleSaveDraft()
                        }) {
                            HStack(spacing: 8) {
                                if isProcessing {
                                    ProgressView()
                                        .tint(AppTheme.primaryText)
                                } else {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.headline)
                                    Text("Save as Draft")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppTheme.secondaryGroupedBackground)
                            .foregroundColor(AppTheme.primaryText)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .disabled(isProcessing)
                        
                        // Send to Review Button
                        Button(action: {
                            handleSendToReview()
                        }) {
                            HStack(spacing: 8) {
                                if isProcessing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.headline)
                                    Text("Send to Review")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppTheme.primaryBlue)
                            .foregroundColor(.white)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isProcessing)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            
            // Success Banner
            if showSuccessBanner {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        Text(successMessage)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    .background(AppTheme.successGreen)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("Course Preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func handleSaveDraft() {
        isProcessing = true
        Task {
            await viewModel.saveDraft()
            
            if let message = viewModel.saveSuccessMessage {
                successMessage = message
                withAnimation {
                    showSuccessBanner = true
                }
                
                // Wait a moment to show the banner
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                // Dismiss the entire modal back to dashboard
                await MainActor.run {
                    // Find and dismiss the root presentation
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.dismiss(animated: true)
                    }
                }
            }
            isProcessing = false
        }
    }
    
    private func handleSendToReview() {
        isProcessing = true
        Task {
            await viewModel.sendToReview()
            
            if let message = viewModel.saveSuccessMessage {
                successMessage = message
                withAnimation {
                    showSuccessBanner = true
                }
                
                // Wait a moment to show the banner
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                // Dismiss the entire modal back to dashboard
                await MainActor.run {
                    // Find and dismiss the root presentation
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.dismiss(animated: true)
                    }
                }
            }
            isProcessing = false
        }
    }

}

// Extension to make Alert easy
extension View {
    func errorAlert(error: Binding<String?>) -> some View {
        self.alert("Error", isPresented: .init(
            get: { error.wrappedValue != nil },
            set: { if !$0 { error.wrappedValue = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = error.wrappedValue {
                Text(error)
            }
        }
    }
}



#Preview {
    NavigationView {
        CoursePreviewView(viewModel: CourseCreationViewModel(educatorID: UUID()))
    }
}
