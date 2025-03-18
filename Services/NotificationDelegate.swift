import Foundation
import UserNotifications
import SwiftUI

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    @Published var deepLinkDestination: DeepLinkDestination?
    
    // For routing in the app based on notification taps
    enum DeepLinkDestination: Equatable {
        case journal(createNew: Bool)
        case thought
    }
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // Called when a notification is delivered to a foreground app
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the notification even if the app is in the foreground
        completionHandler([.banner, .sound])
    }
    
    // Called when a user responds to a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        
        // Extract the notification's userInfo dictionary
        let userInfo = response.notification.request.content.userInfo
        
        // Handle different notification categories
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        
        switch categoryIdentifier {
        case NotificationCategory.journalReminder.rawValue:
            // Check if it's a specific action like "Create Journal Entry"
            if response.actionIdentifier == NotificationAction.openJournal.rawValue {
                deepLinkDestination = .journal(createNew: true)
            } else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
                // The user tapped the notification itself
                if let destination = userInfo["destination"] as? String, destination == "journal" {
                    deepLinkDestination = .journal(createNew: false)
                }
            }
            
        case NotificationCategory.oneTimeReminder.rawValue:
            if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
                if let destination = userInfo["destination"] as? String {
                    switch destination {
                    case "journal":
                        deepLinkDestination = .journal(createNew: false)
                    case "thought":
                        deepLinkDestination = .thought
                    default:
                        break
                    }
                }
            }
            
        default:
            // Handle any other notification categories
            break
        }
    }
    
    // Reset the deep link after it's been processed
    func resetDeepLink() {
        deepLinkDestination = nil
    }
} 