import Foundation
import Combine
import SwiftUI

@MainActor
class RecommendationViewModel: ObservableObject {
    @Published var recommendations: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service = RecommendationService()
    
    func loadRecommendations(userId: UUID) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let courses = try await service.fetchRecommendations(userId: userId)
                self.recommendations = courses
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to load recommendations: \(error.localizedDescription)"
                self.isLoading = false
                print("Recommendation error: \(error)")
            }
        }
    }
}
