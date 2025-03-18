import SwiftUI
import UIKit // For UIScreen

struct LimitReachedView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var usageManager: UsageManager
    
    let onLoginTapped: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Main content in a ScrollView for scrollability
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(.yellow)
                        .padding(.top, 20)
                    
                    Text("Response Limit Reached")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Message
                    Text(limitMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                    
                    // Login/Upgrade button
                    Button(action: onLoginTapped) {
                        Text(actionButtonText)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(authManager.isAnonymous ? Color.blue : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                    
                    // Tier info
                    VStack(spacing: 12) {
                        tierInfoRow(name: "Free", limit: "3 responses total")
                        tierInfoRow(name: "Basic", limit: "8 responses daily", 
                                    isHighlighted: !authManager.isAnonymous && !authManager.isPro)
                        tierInfoRow(name: "Premium", limit: "18 responses daily", 
                                    isHighlighted: authManager.isPro)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground).opacity(0.9))
                )
                .padding(30)
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.8) // Limit max height
        }
    }
    
    // Helper for tier info rows
    private func tierInfoRow(name: String, limit: String, isHighlighted: Bool = false) -> some View {
        HStack {
            Text(name)
                .font(.subheadline)
                .fontWeight(isHighlighted ? .bold : .regular)
                .foregroundColor(isHighlighted ? .primary : .secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(limit)
                .font(.subheadline)
                .foregroundColor(isHighlighted ? .primary : .secondary)
            
            if isHighlighted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding(.horizontal, 10)
    }
    
    // Message changes based on user's tier
    private var limitMessage: String {
        switch usageManager.currentTier {
        case .anonymous:
            return "You've used all 3 of your free responses. Sign in or create an account to get 8 responses every day!"
        case .basic:
            return "You've used all 8 of your daily responses. Upgrade to Premium for 18 responses every day, plus journal features!"
        case .premium:
            return "You've used all 18 of your daily responses for today. Your limit will reset tomorrow."
        }
    }
    
    // Button text changes based on user's status
    private var actionButtonText: String {
        if authManager.isAnonymous {
            return "Sign In / Create Account"
        } else if !authManager.isPro {
            return "Upgrade to Premium"
        } else {
            return "OK"
        }
    }
}

#Preview {
    LimitReachedView(onLoginTapped: {})
        .environmentObject(AuthManager())
        .environmentObject(UsageManager())
} 