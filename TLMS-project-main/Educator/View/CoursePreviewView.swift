import SwiftUI

struct CoursePreviewView: View {
    @ObservedObject var viewModel: CourseCreationViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    @State private var expandedModules: Set<UUID> = []
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.95, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Course Info Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text(viewModel.newCourse.title)
                            .font(.system(size: 24, weight: .bold))
                        
                        Text(viewModel.newCourse.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "folder.fill")
                                .font(.caption)
                            Text(viewModel.newCourse.category)
                                .font(.subheadline)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
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
                                    .font(.system(size: 18))
                                Text("Save as Draft")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.ultraThinMaterial)
                            .background(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
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
                                    .font(.system(size: 18))
                                Text("Send to Review")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.ultraThinMaterial)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
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

// MARK: - Module Preview Card

struct ModulePreviewCard: View {
    let module: Module
    let moduleNumber: Int
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Module Header
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Text("\(moduleNumber)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(module.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(module.lessons.count) lessons")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Lessons List (Expandable)
            if isExpanded {
                Divider()
                    .padding(.horizontal)
                
                VStack(spacing: 0) {
                    ForEach(Array(module.lessons.enumerated()), id: \.element.id) { index, lesson in
                        HStack(spacing: 12) {
                            Image(systemName: lesson.type.icon)
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lesson.title)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Text(lesson.type.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.5))
                        
                        if index < module.lessons.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationView {
        CoursePreviewView(viewModel: CourseCreationViewModel(educatorID: UUID()))
    }
}
