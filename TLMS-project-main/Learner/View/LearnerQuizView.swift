import SwiftUI

struct LearnerQuizView: View {
    let lesson: Lesson

    // MARK: - State
    @State private var currentIndex = 0
    @State private var selectedOptionIndices: Set<Int> = []
    @State private var descriptiveAnswer: String = ""
    @State private var navigateToResult = false

    // MARK: - Data
    private var questions: [Question] {
        lesson.quizQuestions ?? []
    }

    private var currentQuestion: Question? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    private var allowsMultipleSelection: Bool {
        currentQuestion?.type == .multipleChoice
    }

    private var canProceed: Bool {
        guard let question = currentQuestion else { return false }

        switch question.type {
        case .descriptive:
            return !descriptiveAnswer
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        case .singleChoice, .multipleChoice:
            return !selectedOptionIndices.isEmpty
        }
    }

    // MARK: - UI
    var body: some View {
        VStack(spacing: 24) {

            // Progress
            Text("Question \(currentIndex + 1) of \(questions.count)")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)

            if let question = currentQuestion {

                // Question text
                Text(question.text)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.leading)

                // MCQ (single + multiple)
                if question.type != .descriptive {
                    VStack(spacing: 12) {
                        ForEach(question.options.indices, id: \.self) { index in
                            optionButton(
                                text: question.options[index],
                                isSelected: selectedOptionIndices.contains(index)
                            ) {
                                toggleSelection(index)
                            }
                        }
                    }
                }

                // Descriptive answer
                if question.type == .descriptive {
                    TextEditor(text: $descriptiveAnswer)
                        .frame(minHeight: 120)
                        .padding()
                        .background(AppTheme.secondaryGroupedBackground)
                        .cornerRadius(12)
                }

                Spacer()

                // Next / Finish button
                Button(action: handleNextOrFinish) {
                    Text(currentIndex == questions.count - 1 ? "Finish" : "Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            canProceed
                            ? AppTheme.primaryBlue
                            : Color.gray.opacity(0.3)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.cornerRadius)
                }
                .disabled(!canProceed)
            }
        }
        .padding()
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.groupedBackground)

        // ✅ Navigation to grading page
        .navigationDestination(isPresented: $navigateToResult) {
            LearnerQuizResultView(lesson: lesson)
        }
    }

    // MARK: - Logic

    private func toggleSelection(_ index: Int) {
        if allowsMultipleSelection {
            if selectedOptionIndices.contains(index) {
                selectedOptionIndices.remove(index)
            } else {
                selectedOptionIndices.insert(index)
            }
        } else {
            selectedOptionIndices = [index]
        }
    }

    private func handleNextOrFinish() {
        if currentIndex < questions.count - 1 {
            selectedOptionIndices.removeAll()
            descriptiveAnswer = ""
            currentIndex += 1
        } else {
            // ✅ Navigate instead of refreshing
            navigateToResult = true
        }
    }

    // MARK: - Option Button
    private func optionButton(
        text: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.primaryBlue)
                }
            }
            .padding()
            .background(
                isSelected
                ? AppTheme.primaryBlue.opacity(0.1)
                : AppTheme.secondaryGroupedBackground
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

