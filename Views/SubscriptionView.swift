import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTier: SubscriptionTier = .monthly
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(.yellow)
                        
                        Text("Upgrade to Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Unlock premium features to get the most out of your therapy journey")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Subscription Tiers
                    VStack(spacing: 16) {
                        ForEach(SubscriptionTier.allCases.filter { $0 != .free }) { tier in
                            SubscriptionOptionCard(
                                tier: tier,
                                isSelected: selectedTier == tier,
                                action: {
                                    withAnimation {
                                        selectedTier = tier
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Feature comparison
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pro Features Include:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(SubscriptionTier.monthly.features, id: \.self) { feature in
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                Text(feature)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            purchaseSubscription()
                        }) {
                            if subscriptionManager.isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Upgrade Now")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal)
                        .disabled(subscriptionManager.isProcessing)
                        
                        Button("Restore Purchases") {
                            if let userId = authManager.currentUserId {
                                subscriptionManager.restorePurchases(userId: userId)
                            }
                        }
                        .padding(.bottom)
                        .disabled(subscriptionManager.isProcessing)
                    }
                    
                    // Legal info
                    VStack(spacing: 4) {
                        Text("Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Terms of Service • Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Group {
                    if authManager.isAnonymous {
                        Button("Sign In") {
                            // Handle sign in (would show sign in sheet)
                        }
                    } else {
                        EmptyView()
                    }
                }
            )
            .alert(isPresented: $subscriptionManager.showingPurchaseError) {
                Alert(
                    title: Text("Subscription Error"),
                    message: Text(subscriptionManager.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func purchaseSubscription() {
        guard let userId = authManager.currentUserId else {
            subscriptionManager.errorMessage = "You must be signed in to subscribe"
            subscriptionManager.showingPurchaseError = true
            return
        }
        
        if authManager.isAnonymous {
            subscriptionManager.errorMessage = "Please create an account to subscribe"
            subscriptionManager.showingPurchaseError = true
            return
        }
        
        subscriptionManager.purchaseSubscription(tier: selectedTier, userId: userId)
    }
}

struct SubscriptionOptionCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.title)
                        .font(.headline)
                    
                    Text(tier.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(tier.priceString)
                        .font(.headline)
                    
                    if tier == .yearly {
                        Text("Save 20%")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .padding(.leading, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.5), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(UsageManager())
} 
