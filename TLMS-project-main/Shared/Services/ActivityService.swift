import Foundation
import Supabase

@MainActor
final class ActivityService {
    private let supabase = SupabaseManager.shared.client

    func updateLastActive(userId: UUID) async {
        do {
            struct ActivityPayload: Encodable {
                let user_id: String
                let last_active_at: String
            }

            let payload = ActivityPayload(
                user_id: userId.uuidString,
                last_active_at: ISO8601DateFormatter().string(from: Date())
            )

            try await supabase
                .from("learner_activity")
                .upsert(payload)
                .execute()

            print("✅ Activity updated")
        } catch {
            print("❌ Failed to update activity: \(error)")
        }
    }

    func fetchLastActive(userId: UUID) async -> Date? {
        do {
            struct ActivityRow: Decodable {
                let last_active_at: Date
            }

            let row: ActivityRow = try await supabase
                .from("learner_activity")
                .select("last_active_at")
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            return row.last_active_at
        } catch {
            return nil
        }
    }
}
