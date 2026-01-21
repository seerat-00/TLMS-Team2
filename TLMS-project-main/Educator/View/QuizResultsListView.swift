import SwiftUI

struct QuizResultsListView: View {
    let educatorID: UUID
    
    var body: some View {
        VStack {
            Text("Quiz Results")
                .font(.title)
            Text("Coming Soon")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Quiz Results")
    }
}
