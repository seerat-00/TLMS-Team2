import Foundation
import Supabase

class RecommendationService {
    private let supabase: SupabaseClient
    
    init() {
        guard let url = URL(string: SupabaseConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }
        self.supabase = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
    }
    
    // Fetch personalized recommendations
    func fetchRecommendations(userId: UUID) async throws -> [Course] {
        // 1. Try to fetch learner preferences (Phase A)
        var preferences: LearnerPreference?
        
        do {
            preferences = try await supabase
                .from("learner_preferences")
                .select()
                .eq("user_id", value: userId.uuidString)
                .single() // Might throw if no rows, which is fine
                .execute()
                .value
        } catch {
            print("No preferences found or error: \(error)")
            // Continue to fallback
        }
        
        // 2. Build the query
        var query = supabase.from("courses").select()
        
        // Filter by published status if applicable (assuming column exists, if not, remove '.eq("status", ...)')
        // For safety, I'll fetch all and filter in memory if I'm unsure of exact columns, but 'select' usually works.
        // Let's assume 'status' column exists as per my model.
        query = query.eq("status", value: "published")
        
        if let prefs = preferences {
            // Apply filters based on preferences
            // Filter by interest (Category)
            if !prefs.interests.isEmpty {
                // Supabase 'in' filter expects comma separated string for some clients, or array.
                // For swift client: .in("column", values: [values])
                 query = query.in("category", values: prefs.interests)
            }
            
            // Filter by skill level?
            // Maybe relax this if too strict.
            // query = query.eq("level", value: prefs.skillLevel)
        }
        
        // Limit to top 5
        // Limit to top 5 and execute
        let courses: [Course] = try await query.limit(5).execute().value
        return courses
    }
    
    // For Phase B: Fetch activity based recommendations (Placeholder logic)
    // We could check 'enrollments' table and see what categories they consume.
}
