import Foundation
import UserNotifications

final class LocalNotificationManager {
    static let shared = LocalNotificationManager()
    private init() {}
    private let deadlinePrefix = "DEADLINE_REMINDER_"   // NEW ✅
    private let reminderIdentifier = "DAILY_STUDY_REMINDER"
    
    // Ask permission
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    // Schedule daily reminder
    func scheduleDailyReminder(hour: Int, minute: Int) async {
        // Remove old reminder first
        await cancelDailyReminder()
        
        let content = UNMutableNotificationContent()
        content.title = "Time to study 📚"
        content.body = "Keep your streak alive. Complete one lesson today!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Daily reminder scheduled at \(hour):\(minute)")
        } catch {
            print("❌ Failed to schedule reminder:", error.localizedDescription)
        }
    }
    
    // Cancel
    func cancelDailyReminder() async {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
        
        print("🛑 Daily reminder cancelled")
    }
    // MARK: - Deadline Reminders (NEW ✅)
        
        /// schedule one deadline reminder at specific date-time
        func scheduleDeadlineReminder(deadlineId: UUID, title: String, deadlineAt: Date) async {
            let identifier = "\(deadlinePrefix)\(deadlineId.uuidString)"
            
            // remove old same reminder (update scenario)
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: [identifier])
            
            let content = UNMutableNotificationContent()
            content.title = "Deadline Reminder ⏰"
            content.body = "\(title) deadline is near. Complete it soon!"
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(5, deadlineAt.timeIntervalSinceNow),
                repeats: false
            )
            
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("✅ Deadline reminder scheduled:", identifier)
            } catch {
                print("❌ Failed deadline reminder:", error.localizedDescription)
            }
        }
        
        /// cancel all deadline reminders
        func cancelAllDeadlineReminders() {
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let ids = requests
                    .map { $0.identifier }
                    .filter { $0.hasPrefix(self.deadlinePrefix) }
                
                UNUserNotificationCenter.current()
                    .removePendingNotificationRequests(withIdentifiers: ids)
                
                print("🛑 Cancelled all deadline reminders:", ids.count)
            }
        }
}
