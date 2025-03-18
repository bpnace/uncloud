import SwiftUI

enum Tab {
    case home
    case journal
    case profile
    case settings
}

struct MainView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var usageManager: UsageManager
    @State private var selectedTab: Tab = .home
    @EnvironmentObject private var notificationDelegate: NotificationDelegate
    @State private var showJournalCreation = false
    
    // Listen for deep link navigation
    private let journalNotification = NotificationCenter.default.publisher(for: Notification.Name("NavigateToJournal"))
    private let thoughtNotification = NotificationCenter.default.publisher(for: Notification.Name("NavigateToThought"))
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Thoughts Tab - Available to all users
            ThoughtCaptureView()
                .tabItem {
                    Label("Thoughts", systemImage: "brain")
                }
                .tag(Tab.home)
            
            // Journal Tab - Only for Pro users
            if authManager.isPro {
                JournalView()
                    .tabItem {
                        Label("Journal", systemImage: "book")
                    }
                    .tag(Tab.journal)
            }
            
            // Profile Tab - For all registered (non-anonymous) users
            if !authManager.isAnonymous {
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                    .tag(Tab.profile)
            }
            
            // Settings Tab - Available to all users
            SettingsView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .onReceive(journalNotification) { notification in
            // Navigate to journal tab
            selectedTab = .journal
            
            // If createNew is true, trigger the journal creation sheet
            if let userInfo = notification.userInfo, 
               let createNew = userInfo["createNew"] as? Bool, 
               createNew {
                showJournalCreation = true
            }
        }
        .onReceive(thoughtNotification) { _ in
            // Navigate to home tab (thought capture)
            selectedTab = .home
        }
        .sheet(isPresented: $showJournalCreation) {
            if authManager.isPro {
                JournalEntryCreationView()
            }
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