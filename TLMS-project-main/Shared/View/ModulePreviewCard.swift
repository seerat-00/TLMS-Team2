import SwiftUI

struct ModulePreviewCard: View {
    let module: Module
    let moduleNumber: Int
    let isExpanded: Bool
    let isEnrolled: Bool  // NEW: enrollment status
    let onToggle: () -> Void
    let onLessonTap: (Lesson) -> Void   // 👈 NEW (navigation delegated to parent)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Module Header
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.primaryAccent.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Text("\(moduleNumber)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.primaryAccent)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(module.title)
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryText)

                        Text("\(module.lessons.count) lessons")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // MARK: - Lessons List (Expandable)
            if isExpanded {
                Divider()
                    .padding(.horizontal)

                VStack(spacing: 0) {
                    ForEach(Array(module.lessons.enumerated()), id: \.element.id) { index, lesson in

                        HStack(spacing: 12) {
                            Image(systemName: lesson.type.icon)
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.primaryAccent)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(lesson.title)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.primaryText)

                                Text(lesson.type.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.secondaryText)
                            }

                            Spacer()
                            
                            // Show lock icon if not enrolled
                            if !isEnrolled {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.secondaryText.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppTheme.secondaryGroupedBackground.opacity(0.5))
                        .contentShape(Rectangle())              // 👈 makes full row tappable
                        .onTapGesture {
                            onLessonTap(lesson)                // 👈 delegate navigation
                        }
                        .opacity(isEnrolled ? 1.0 : 0.6)  // Dim unenrolled lessons

                        if index < module.lessons.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
        }
        .background(AppTheme.secondaryGroupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

