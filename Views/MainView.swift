import SwiftUI

struct MainView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var usageManager: UsageManager
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Thoughts Tab - Available to all users
            ThoughtCaptureView()
                .tabItem {
                    Label("Thoughts", systemImage: "brain")
                }
                .tag(0)
            
            // Journal Tab - Only for Pro users
            if authManager.isPro {
                JournalView()
                    .tabItem {
                        Label("Journal", systemImage: "book")
                    }
                    .tag(1)
            }
            
            // Profile Tab - For all registered (non-anonymous) users
            if !authManager.isAnonymous {
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                    .tag(authManager.isPro ? 2 : 1)
            }
            
            // Settings Tab - Available to all users
            SettingsView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(getSettingsTabTag())
        }
    }
    
    // Helper method to determine the correct tag for Settings tab
    private func getSettingsTabTag() -> Int {
        if authManager.isPro {
            return 3 // Pro user: Thoughts(0), Journal(1), Profile(2), Settings(3)
        } else if !authManager.isAnonymous {
            return 2 // Basic user: Thoughts(0), Profile(1), Settings(2)
        } else {
            return 1 // Anonymous user: Thoughts(0), Settings(1)
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(UsageManager())
} 