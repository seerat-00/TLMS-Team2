import SwiftUI

struct RecommendationListView: View {
    let userId: UUID
    @StateObject private var viewModel = RecommendationViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Recommended for You")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !viewModel.recommendations.isEmpty {
                    Button("See All") {
                        // Action to see all recommendations
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Content
            ZStack {
                if viewModel.isLoading {
                    // Skeleton Loader
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(0..<3) { _ in
                                RecommendationSkeletonCard()
                            }
                        }
                        .padding(.horizontal)
                    }
                } else if let error = viewModel.errorMessage {
                    // Error State (Fail silently or show message)
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Could not load recommendations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else if viewModel.recommendations.isEmpty {
                    // Empty State
                    VStack(spacing: 12) {
                        Image(systemName: "lightbulb.slash")
                            .font(.largeTitle)
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No recommendations available right now.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    // List
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.recommendations) { course in
                                RecommendationCard(course: course)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10) // for shadow
                    }
                }
            }
        }
        .onAppear {
            if viewModel.recommendations.isEmpty {
                viewModel.loadRecommendations(userId: userId)
            }
        }
    }
}

// Skeleton Card for Loading State
struct RecommendationSkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 140)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 6) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 12)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 16)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 16)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 240)
    }
}
