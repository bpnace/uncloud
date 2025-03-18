import Foundation
import SwiftData

@Model
final class User {
    // Basic properties
    var id: String // Firebase Auth UID
    var email: String?
    var displayName: String?
    var createdAt: Date
    var lastLoginAt: Date
    
    // Subscription status
    var isPro: Bool
    var proExpirationDate: Date?
    var stripeCustomerId: String?
    
    // User preferences
    var notificationsEnabled: Bool
    var aiTonePreference: String? // For Pro customization
    var privacyModeEnabled: Bool // Offline-only mode
    
    // Stats
    var thoughtCount: Int
    var journalEntryCount: Int
    
    init(
        id: String,
        email: String? = nil,
        displayName: String? = nil,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date(),
        isPro: Bool = false,
        proExpirationDate: Date? = nil,
        stripeCustomerId: String? = nil,
        notificationsEnabled: Bool = true,
        aiTonePreference: String? = nil,
        privacyModeEnabled: Bool = false,
        thoughtCount: Int = 0,
        journalEntryCount: Int = 0
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.isPro = isPro
        self.proExpirationDate = proExpirationDate
        self.stripeCustomerId = stripeCustomerId
        self.notificationsEnabled = notificationsEnabled
        self.aiTonePreference = aiTonePreference
        self.privacyModeEnabled = privacyModeEnabled
        self.thoughtCount = thoughtCount
        self.journalEntryCount = journalEntryCount
    }
} 