import Foundation
import SwiftData
import Combine

// Define user tiers and their limits
enum UserTier {
    case anonymous    // 3 responses total, basic UI
    case basic        // 8 responses per day, basic UI
    case premium      // 18 responses per day, full UI
    
    var responseLimit: Int {
        switch self {
        case .anonymous: return 3
        case .basic: return 8
        case .premium: return 18
        }
    }
    
    var isPeriodic: Bool {
        switch self {
        case .anonymous: return false  // Total limit
        case .basic, .premium: return true  // Daily limit
        }
    }
}

class UsageManager: ObservableObject {
    // Published properties for UI updates
    @Published var currentTier: UserTier = .anonymous
    @Published var responseCount: Int = 0
    @Published var responsesRemaining: Int = 0
    @Published var limitReached: Bool = false
    
    // For tracking when daily limits reset
    private var lastResetDate: Date?
    private var userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // Reference to HuggingFaceService
    private let huggingFaceService = HuggingFaceService()
    
    // Keys for UserDefaults
    private let responseCountKey = "responseCount"
    private let lastResetDateKey = "lastResetDate"
    private let lifetimeTotalKey = "lifetimeTotal"
    
    init() {
        // Load initial values
        loadSavedUsage()
    }
    
    // Set the user tier based on authentication and subscription status
    func setUserTier(isAuthenticated: Bool, isAnonymous: Bool, isPro: Bool) {
        if isPro {
            currentTier = .premium
            huggingFaceService.useDefaultAPIKey() // Pro users get the full API key
        } else if isAuthenticated && !isAnonymous {
            currentTier = .basic
            huggingFaceService.useDefaultAPIKey() // Basic users get the full API key
        } else {
            currentTier = .anonymous
            huggingFaceService.useFreeTierAPIKey() // Anonymous users get the free tier API key
        }
        
        checkDailyReset()
        updateRemainingResponses()
    }
    
    // Increment response count when user receives a response
    func incrementResponseCount() {
        checkDailyReset()
        
        responseCount += 1
        incrementLifetimeTotal()
        
        updateRemainingResponses()
        saveCurrentUsage()
    }
    
    // Check if user can request a new response
    func canRequestResponse() -> Bool {
        checkDailyReset()
        return responsesRemaining > 0
    }
    
    // Reset usage for a new user (when signing out)
    func resetUsage() {
        responseCount = 0
        lastResetDate = nil
        updateRemainingResponses()
        saveCurrentUsage()
    }
    
    // Completely new implementation for development testing
    func devReset() {
        // Clear all counters in UserDefaults
        userDefaults.removeObject(forKey: responseCountKey)
        userDefaults.removeObject(forKey: lastResetDateKey)
        
        // Force reset of all properties
        responseCount = 0
        lastResetDate = Date()
        limitReached = false
        
        // Calculate remaining responses
        let limit = currentTier.responseLimit
        responsesRemaining = limit
        
        // Sync to UserDefaults
        userDefaults.set(0, forKey: responseCountKey)
        userDefaults.set(Date(), forKey: lastResetDateKey)
        userDefaults.synchronize()
        
        // Force immediate UI update
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
        #if DEBUG
        print("🧪 DEV RESET: Usage counters cleared. \(responsesRemaining) responses now available.")
        #endif
    }
    
    // Mark the old reset method as deprecated to avoid using it
    @available(*, deprecated, message: "This method may cause UI freezes. Use devReset() instead.")
    func resetForTesting() {
        devReset() // Call the new implementation
    }
    
    // Private methods
    
    // Check if we need to reset daily counts
    private func checkDailyReset() {
        // Skip for anonymous users (total limit, not daily)
        if currentTier == .anonymous {
            return
        }
        
        // Check if we need to reset based on day change
        if let lastReset = lastResetDate {
            let calendar = Calendar.current
            if !calendar.isDate(lastReset, inSameDayAs: Date()) {
                // It's a new day, reset the counter
                responseCount = 0
                lastResetDate = Date()
                saveCurrentUsage()
            }
        } else {
            // First time, set the reset date
            lastResetDate = Date()
            saveCurrentUsage()
        }
    }
    
    // Update the remaining responses count
    private func updateRemainingResponses() {
        let limit = currentTier.responseLimit
        responsesRemaining = max(0, limit - responseCount)
        limitReached = responsesRemaining <= 0
    }
    
    // Track lifetime total responses
    private func incrementLifetimeTotal() {
        let current = userDefaults.integer(forKey: lifetimeTotalKey)
        userDefaults.set(current + 1, forKey: lifetimeTotalKey)
    }
    
    // Load saved usage data
    private func loadSavedUsage() {
        responseCount = userDefaults.integer(forKey: responseCountKey)
        lastResetDate = userDefaults.object(forKey: lastResetDateKey) as? Date
        
        // Default to anonymous tier until properly set
        currentTier = .anonymous
        huggingFaceService.useFreeTierAPIKey() // Start with free tier API key
        updateRemainingResponses()
    }
    
    // Save current usage data
    private func saveCurrentUsage() {
        userDefaults.set(responseCount, forKey: responseCountKey)
        userDefaults.set(lastResetDate, forKey: lastResetDateKey)
    }
} 