import Foundation
import Combine

enum SubscriptionTier: String, CaseIterable, Identifiable {
    case free = "Free"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .free: return "Free"
        case .monthly: return "Pro Monthly"
        case .yearly: return "Pro Yearly"
        }
    }
    
    var description: String {
        switch self {
        case .free:
            return "Limited features with 24-hour data expiry"
        case .monthly:
            return "All Pro features, billed monthly"
        case .yearly:
            return "All Pro features, billed yearly (save 20%)"
        }
    }
    
    var price: Decimal {
        switch self {
        case .free: return 0
        case .monthly: return 4.99
        case .yearly: return 47.99 // ~$4 per month, 20% savings
        }
    }
    
    var priceString: String {
        switch self {
        case .free: return "Free"
        case .monthly: return "$4.99/month"
        case .yearly: return "$47.99/year"
        }
    }
    
    var stripePriceId: String? {
        switch self {
        case .free: return nil
        case .monthly: return "price_monthly_placeholder" // Replace with actual Stripe price ID
        case .yearly: return "price_yearly_placeholder" // Replace with actual Stripe price ID
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "AI Therapeutic Responses",
                "Basic Widget",
                "Data deleted after 24 hours",
                "Anonymous usage"
            ]
        case .monthly, .yearly:
            return [
                "Everything in Free",
                "Persistent journaling",
                "Tags and mood tracking",
                "Daily reminders",
                "Custom therapeutic sessions",
                "AI tone personalization",
                "Enhanced Widget"
            ]
        }
    }
}

class SubscriptionService {
    // This will store subscription events
    var subscriptionStatusPublisher = PassthroughSubject<Bool, Never>()
    
    // Sample method for initiating purchase
    func purchase(tier: SubscriptionTier, userId: String, completion: @escaping (Bool, Error?) -> Void) {
        // In a real implementation, this would:
        // 1. Initialize Stripe payment sheet
        // 2. Handle payment processing
        // 3. Verify purchase with server
        // 4. Update user's subscription status
        
        print("Initiating purchase for \(tier.title) at \(tier.priceString)")
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Simulate successful purchase
            self.subscriptionStatusPublisher.send(true)
            completion(true, nil)
        }
    }
    
    // Check subscription status from backend
    func verifySubscription(for userId: String) -> AnyPublisher<Bool, Error> {
        // In a real implementation, this would:
        // 1. Call your backend API to verify subscription status with Stripe
        // 2. Update local user model with subscription details
        
        // For now, simulate a network request
        return Future<Bool, Error> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // Simulate successful verification
                promise(.success(false))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // Restore purchases
    func restorePurchases(userId: String, completion: @escaping (Bool, Error?) -> Void) {
        // In a real implementation, this would:
        // 1. Call Stripe API to get user's active subscriptions
        // 2. Update local state
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Simulate no active subscriptions found
            completion(false, nil)
        }
    }
    
    // Get expiration date for current subscription
    func getExpirationDate(for userId: String) -> AnyPublisher<Date?, Error> {
        // In a real implementation, check with Stripe for the subscription end date
        return Future<Date?, Error> { promise in
            let futureDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
            promise(.success(futureDate))
        }
        .eraseToAnyPublisher()
    }
} 