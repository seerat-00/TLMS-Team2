import SwiftUI

struct CoursePreviewView: View {
    @ObservedObject var viewModel: CourseCreationViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    @State private var expandedModules: Set<UUID> = []
    
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
                                    onToggle: {
                                        if expandedModules.contains(module.id) {
                                            expandedModules.remove(module.id)
                                        } else {
                                            expandedModules.insert(module.id)
                                        }
                                    }
                                )
                            }
                        }
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            // Save as Draft Button
                            Button(action: {
                                viewModel.saveDraft()
                                // Navigate back to root (dashboard)
                                presentationMode.wrappedValue.dismiss()
                                // Dismiss all the way back
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.headline)
                                    Text("Save as Draft")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(AppTheme.secondaryGroupedBackground)
                                .foregroundColor(AppTheme.primaryText)
                                .cornerRadius(AppTheme.cornerRadius)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                            
                            // Send to Review Button
                            Button(action: {
                                viewModel.sendToReview()
                                // Navigate back to root (dashboard)
                                presentationMode.wrappedValue.dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "paperplane.fill")
                                        .font(.headline)
                                    Text("Send to Review")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(AppTheme.primaryBlue)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.cornerRadius)
                                .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Course Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    


#Preview {
    NavigationView {
        CoursePreviewView(viewModel: CourseCreationViewModel(educatorID: UUID()))
    }
}
