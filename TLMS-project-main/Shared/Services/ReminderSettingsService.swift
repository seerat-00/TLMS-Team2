import Foundation
import Supabase

@MainActor
final class ReminderSettingsService {
    
    private let supabase: SupabaseClient
    
    init() {
        self.supabase = SupabaseManager.shared.client
    }
    
    struct ReminderSettings: Codable {
        let userId: UUID
        var enabled: Bool
        var reminderTime: String   // "HH:mm:ss"
        
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case enabled
            case reminderTime = "reminder_time"
        }
    }
    
    // MARK: - Fetch
    func fetchSettings(userId: UUID) async -> ReminderSettings? {
        do {
            let settings: ReminderSettings = try await supabase
                .from("learner_reminder_settings")
                .select()
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            return settings
        } catch {
            // If not found, create default
            return await createDefaultSettingsIfMissing(userId: userId)
        }
    }
    
    // MARK: - Save / Upsert
    func saveSettings(userId: UUID, enabled: Bool, reminderTime: String) async -> Bool {
        do {
            let settings = ReminderSettings(
                userId: userId,
                enabled: enabled,
                reminderTime: reminderTime
            )
            
            try await supabase
                .from("learner_reminder_settings")
                .upsert(settings)
                .execute()
            
            return true
        } catch {
            print("❌ Reminder save failed:", error.localizedDescription)
            return false
        }
    }
    
    private func createDefaultSettingsIfMissing(userId: UUID) async -> ReminderSettings? {
        let defaultSettings = ReminderSettings(
            userId: userId,
            enabled: false,
            reminderTime: "20:00:00"
        )
        
        do {
            try await supabase
                .from("learner_reminder_settings")
                .upsert(defaultSettings)
                .execute()
            
            return defaultSettings
        } catch {
            print("❌ Default reminder settings create failed:", error.localizedDescription)
            return nil
        }
    }
}
