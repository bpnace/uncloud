import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let result = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            DispatchQueue.main.async {
                self.isAuthorized = result
            }
            return result
        } catch {
            print("Error requesting notification authorization: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Notification Management
    
    func scheduleJournalReminder(at time: Date, repeats: Bool = true) async -> String? {
        let content = UNMutableNotificationContent()
        content.title = "Journal Reminder"
        content.body = "Take a moment to reflect on your day with a journal entry."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.journalReminder.rawValue
        content.userInfo = ["destination": "journal"]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: repeats
        )
        
        // Create the request
        let id = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            await refreshPendingNotifications()
            return id
        } catch {
            print("Error scheduling notification: \(error.localizedDescription)")
            return nil
        }
    }
    
    func scheduleOneTimeReminder(at time: Date, title: String, body: String) async -> String? {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.oneTimeReminder.rawValue
        content.userInfo = ["destination": "journal"]
        
        // Create trigger (one-time)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: time),
            repeats: false
        )
        
        // Create the request
        let id = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            await refreshPendingNotifications()
            return id
        } catch {
            print("Error scheduling one-time notification: \(error.localizedDescription)")
            return nil
        }
    }
    
    func cancelNotification(withIdentifier id: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        await refreshPendingNotifications()
    }
    
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        await refreshPendingNotifications()
    }
    
    func refreshPendingNotifications() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        DispatchQueue.main.async {
            self.pendingNotifications = requests
        }
    }
    
    // MARK: - Notification Setup
    
    func registerNotificationCategories() {
        // Journal reminder category with actions
        let journalAction = UNNotificationAction(
            identifier: NotificationAction.openJournal.rawValue,
            title: "Create Journal Entry",
            options: .foreground
        )
        
        let journalReminderCategory = UNNotificationCategory(
            identifier: NotificationCategory.journalReminder.rawValue,
            actions: [journalAction],
            intentIdentifiers: [],
            options: []
        )
        
        // One-time reminder category
        let oneTimeReminderCategory = UNNotificationCategory(
            identifier: NotificationCategory.oneTimeReminder.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        // Register the categories
        notificationCenter.setNotificationCategories([journalReminderCategory, oneTimeReminderCategory])
    }
}

// MARK: - Notification Types

enum NotificationCategory: String {
    case journalReminder = "journalReminder"
    case oneTimeReminder = "oneTimeReminder"
}

enum NotificationAction: String {
    case openJournal = "openJournal"
}

// MARK: - Helper Extensions

extension Date {
    func toNextOccurrence(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        var date = calendar.date(from: components) ?? self
        
        // If the time today has already passed, schedule for tomorrow
        if date < self {
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? self
        }
        
        return date
    }
} 