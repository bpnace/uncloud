import SwiftUI
import UIKit // For UIScreen

struct LimitReachedView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var usageManager: UsageManager
    @Environment(\.colorScheme) var colorScheme
    
    let onLoginTapped: () -> Void
    let onDismissTapped: () -> Void
    
    // Animations
    @State private var showContent = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Blurred background overlay
            BlurredBackground()
            
            // Main content
            VStack(spacing: 0) {
                // Top icon/animation area
                VStack {
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(colorScheme == .dark ? 
                                  Color.yellow.opacity(0.15) : 
                                  Color.yellow.opacity(0.2))
                            .frame(width: 110, height: 110)
                        
                        // Pulsing circle for animation
                        Circle()
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
                            .frame(width: 130, height: 130)
                            .scaleEffect(pulseScale)
                        
                        // Icon
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 60, weight: .light))
                            .foregroundStyle(Color.yellow)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .padding(.top, 20)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            pulseScale = 1.2
                        }
                    }
                    
                    // Title
                    Text("Daily Limit Reached")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .padding(.top, 16)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : -20)
                
                // Message
                Text(limitMessage)
                    .font(.system(size: 16, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                    .foregroundColor(.secondary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -10)
                
                // Tier comparison card
                TierComparisonCard()
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                // Action button
                Button(action: onLoginTapped) {
                    HStack {
                        Text(actionButtonText)
                            .font(.headline)
                        
                        if actionButtonText.contains("Sign In") || actionButtonText.contains("Upgrade") {
                            Image(systemName: actionButtonText.contains("Sign In") ? "arrow.right.circle.fill" : "sparkles")
                                .font(.system(size: 16))
                                .offset(x: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: authManager.isAnonymous ? 
                                Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]) :
                                Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.85)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: authManager.isAnonymous ? Color.blue.opacity(0.3) : Color.accentColor.opacity(0.3), 
                            radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)
                
                // Maybe later option
                if !authManager.isPro {
                    Button(action: {
                        // Dismiss the overlay
                        onDismissTapped()
                    }) {
                        Text("Maybe later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 24)
                    .opacity(showContent ? 1 : 0)
                }
            }
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                    showContent = true
                }
            }
        }
    }
    
    // Blurred background component
    private struct BlurredBackground: View {
        var body: some View {
            Color.black.opacity(0.4)
                .background(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    // Tier comparison card component
    private func TierComparisonCard() -> some View {
        VStack(spacing: 0) {
            // Header
            Text("Your AI Response Plan")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Tier rows
            VStack(spacing: 2) {
                tierInfoRow(name: "Free", 
                           limit: "3 responses total",
                           icon: "circle.dotted",
                           isHighlighted: usageManager.currentTier == .anonymous)
                
                tierInfoRow(name: "Basic", 
                           limit: "8 responses daily", 
                           icon: "person.fill",
                           isHighlighted: usageManager.currentTier == .basic)
                
                tierInfoRow(name: "Premium", 
                           limit: "18 responses daily", 
                           icon: "star.fill",
                           isHighlighted: usageManager.currentTier == .premium)
            }
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // Helper for tier info rows with improved design
    private func tierInfoRow(name: String, limit: String, icon: String, isHighlighted: Bool = false) -> some View {
        HStack(spacing: 16) {
            // Tier icon
            ZStack {
                Circle()
                    .fill(isHighlighted ? 
                          Color.accentColor.opacity(0.15) : 
                          Color.gray.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isHighlighted ? Color.accentColor : Color.gray)
            }
            
            // Tier name and limit
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: isHighlighted ? .semibold : .regular))
                    .foregroundColor(isHighlighted ? .primary : .secondary)
                
                Text(limit)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Current plan indicator
            if isHighlighted {
                Text("Current")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.15))
                    )
                    .foregroundColor(Color.accentColor)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .contentShape(Rectangle())
    }
    
    // Message changes based on user's tier
    private var limitMessage: String {
        switch usageManager.currentTier {
        case .anonymous:
            return "You've used all 3 of your free responses.\nCreate an account to get 8 AI responses every day!"
        case .basic:
            return "You've used all 8 of your daily responses.\nUpgrade to Premium for more responses and unlock journal features!"
        case .premium:
            return "You've used all 18 of your daily premium responses for today.\nYour limit will reset at midnight."
        }
    }
    
    // Button text changes based on user's status
    private var actionButtonText: String {
        if authManager.isAnonymous {
            return "Sign In / Create Account"
        } else if !authManager.isPro {
            return "Upgrade to Premium"
        } else {
            return "Got it"
        }
    }
}

#Preview {
    LimitReachedView(onLoginTapped: {}, onDismissTapped: {})
        .environmentObject(AuthManager())
        .environmentObject(UsageManager())
} 