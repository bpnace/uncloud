import Foundation
import Combine
import SwiftData

class SubscriptionManager: ObservableObject {
    @Published var isProcessing = false
    @Published var currentTier: SubscriptionTier = .free
    @Published var expirationDate: Date?
    @Published var showingPurchaseError = false
    @Published var errorMessage = ""
    
    private let subscriptionService = SubscriptionService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to subscription status updates
        subscriptionService.subscriptionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPro in
                self?.updateSubscriptionState(isPro: isPro)
            }
            .store(in: &cancellables)
    }
    
    // Check current subscription status
    func checkSubscriptionStatus(for userId: String) {
        isProcessing = true
        
        subscriptionService.verifySubscription(for: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isProcessing = false
                    
                    if case .failure(let error) = completion {
                        self?.showError("Failed to verify subscription: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] isPro in
                    self?.updateSubscriptionState(isPro: isPro)
                    
                    // If user has Pro subscription, fetch expiration date
                    if isPro {
                        self?.fetchExpirationDate(for: userId)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Purchase subscription
    func purchaseSubscription(tier: SubscriptionTier, userId: String) {
        guard tier != .free else { return }
        isProcessing = true
        
        subscriptionService.purchase(tier: tier, userId: userId) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isProcessing = false
                
                if success {
                    self?.currentTier = tier
                    
                    // In a real app, we would now fetch the updated expiration date
                    self?.fetchExpirationDate(for: userId)
                } else if let error = error {
                    self?.showError("Purchase failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Restore purchases
    func restorePurchases(userId: String) {
        isProcessing = true
        
        subscriptionService.restorePurchases(userId: userId) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isProcessing = false
                
                if let error = error {
                    self?.showError("Restore failed: \(error.localizedDescription)")
                } else if !success {
                    self?.showError("No active subscriptions found")
                } else {
                    // Update our local state if restoration was successful
                    self?.checkSubscriptionStatus(for: userId)
                }
            }
        }
    }
    
    // Update local subscription state
    private func updateSubscriptionState(isPro: Bool) {
        currentTier = isPro ? .monthly : .free
    }
    
    // Fetch expiration date for display
    private func fetchExpirationDate(for userId: String) {
        subscriptionService.getExpirationDate(for: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] date in
                    self?.expirationDate = date
                }
            )
            .store(in: &cancellables)
    }
    
    // Update user model with subscription info
    func updateUserSubscription(user: User, isPro: Bool, expirationDate: Date?) {
        user.isPro = isPro
        user.proExpirationDate = expirationDate
        
        // In a real app, would also update the backend
    }
    
    // Helper to show error message
    private func showError(_ message: String) {
        errorMessage = message
        showingPurchaseError = true
    }
} 