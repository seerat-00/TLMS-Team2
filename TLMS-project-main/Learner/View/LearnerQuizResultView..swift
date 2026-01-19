import SwiftUI

struct LearnerQuizResultView: View {
    let lesson: Lesson

    var body: some View {
        ZStack {
            AppTheme.groupedBackground
                .ignoresSafeArea()   // ← critical

            VStack(spacing: 24) {

                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundColor(AppTheme.primaryBlue)

                Text("Quiz Submitted")
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.primaryText)

                Text("Your quiz has been submitted for grading.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if lesson.quizQuestions?.contains(where: { $0.requiresManualGrading }) == true {
                    Text("Some answers require manual grading.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Quiz Result")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar) // ← OPTIONAL but recommended
    }
}

