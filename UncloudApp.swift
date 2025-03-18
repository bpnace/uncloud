//
//  UncloudApp.swift
//  Uncloud
//
//  Created by Tarik Marshall on 13.03.25.
//

import SwiftUI
import SwiftData
import Combine

@main
struct UncloudApp: App {
    // State for splash screen
    @State private var isShowingSplash = true
    
    var sharedModelContainer: ModelContainer = {
        // Delete existing database files
        let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let persistentStoreLocation = applicationSupportDirectory.appendingPathComponent("default.store")
        try? FileManager.default.removeItem(at: persistentStoreLocation)
        
        // Define the schema
        let schema = Schema([
            Thought.self,
            User.self,
            JournalEntry.self,
            AppSettings.self
        ])
        
        // Create a standard configuration
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: false)
        
        do {
            // Create the container with clean files
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Failed to create ModelContainer: \(error). Falling back to in-memory database.")
            
            // Last resort: in-memory only
            let inMemoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [inMemoryConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()
    
    // Environment objects for app-wide state
    @StateObject private var authManager = AuthManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var usageManager = UsageManager()
    @StateObject private var notificationDelegate = NotificationDelegate()
    
    // Setup cleanup timer for anonymous data
    @State private var cleanupTimer: Timer? = nil
    
    // Add Hugging Face service initialization
    private let huggingFaceService = HuggingFaceService()

    var body: some Scene {
        WindowGroup {
            ZStack {
                OnboardingView()
                    .environmentObject(authManager)
                    .environmentObject(themeManager)
                    .environmentObject(subscriptionManager)
                    .environmentObject(usageManager)
                    .environmentObject(notificationDelegate)
                    .onAppear {
                        setupDataManager()
                        setupCleanupTimer()
                        setupUsageManager()
                        
                        // Ensure Hugging Face service is initialized with default API key
                        huggingFaceService.useDefaultAPIKey()
                        
                        // Create AppSettings with default Hugging Face configuration if none exists
                        ensureAppSettingsExist()
                        
                        // Register for notifications
                        UNUserNotificationCenter.current().delegate = notificationDelegate
                    }
                    .onChange(of: authManager.isAuthenticated) { _, newValue in
                        // Update DataManager with authentication status
                        DataManager.shared.setAuthState(
                            isAnonymous: !newValue || authManager.isAnonymous,
                            userId: authManager.currentUserId
                        )
                        
                        // Update usage manager with user status
                        updateUsageManagerTier()
                        
                        // If signing out, handle data cleanup
                        if !newValue {
                            DataManager.shared.handleSignOut()
                            usageManager.resetUsage()
                        }
                    }
                    .onChange(of: authManager.isPro) { _, _ in
                        // Update tier when pro status changes
                        updateUsageManagerTier()
                    }
                    .onChange(of: notificationDelegate.deepLinkDestination) { _, destination in
                        if let destination = destination {
                            handleDeepLink(destination)
                            notificationDelegate.resetDeepLink()
                        }
                    }
                
                // Show splash screen if needed
                if isShowingSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                        .onAppear {
                            // Schedule splash screen dismissal
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isShowingSplash = false
                                }
                            }
                        }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // Initialize the data manager with the shared model container
    private func setupDataManager() {
        DataManager.shared.setModelContext(sharedModelContainer.mainContext)
    }
    
    // Set up a timer to clean up expired thoughts for anonymous users
    private func setupCleanupTimer() {
        // Clean up on launch
        Task {
            await DataManager.shared.cleanupExpiredThoughts()
        }
        
        // Set up a timer to clean up every hour
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task {
                await DataManager.shared.cleanupExpiredThoughts()
            }
        }
    }
    
    // Setup the usage manager with initial user status
    private func setupUsageManager() {
        updateUsageManagerTier()
    }
    
    // Update usage manager tier based on authentication status
    private func updateUsageManagerTier() {
        usageManager.setUserTier(
            isAuthenticated: authManager.isAuthenticated,
            isAnonymous: authManager.isAnonymous,
            isPro: authManager.isPro
        )
    }
    
    // Ensure application settings exist
    private func ensureAppSettingsExist() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<AppSettings>()
        
        do {
            let existingSettings = try context.fetch(descriptor)
            if existingSettings.isEmpty {
                // Create default settings if none exist
                let settings = AppSettings()
                settings.selectedAIProvider = "huggingface"
                settings.useDefaultHuggingFaceKey = true
                settings.huggingFaceAPIKeySet = true
                settings.selectedHuggingFaceModel = "google/gemma-2-2b-it"
                
                context.insert(settings)
                try context.save()
            }
        } catch {
            print("Error ensuring AppSettings exist: \(error)")
        }
    }
    
    private func handleDeepLink(_ destination: NotificationDelegate.DeepLinkDestination) {
        // Implement app-specific navigation based on the deep link destination
        switch destination {
        case .journal(let createNew):
            // Navigate to journal tab and create new entry if requested
            NotificationCenter.default.post(
                name: Notification.Name("NavigateToJournal"),
                object: nil,
                userInfo: ["createNew": createNew]
            )
            
        case .thought:
            // Navigate to thought capture tab
            NotificationCenter.default.post(
                name: Notification.Name("NavigateToThought"),
                object: nil
            )
        }
    }
}

// Simple manager classes for app-wide state
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isAnonymous = true
    @Published var currentUserId: String?
    @Published var isPro = false
    
    private let authService = AuthService()
    private var cancellables = Set<AnyCancellable>()
    
    // Sign in anonymously
    func signInAnonymously() {
        authService.signInAnonymously()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        // Handle error
                        self?.isAuthenticated = false
                        self?.isAnonymous = true
                        self?.currentUserId = nil
                    }
                },
                receiveValue: { [weak self] userId in
                    self?.isAuthenticated = true
                    self?.isAnonymous = true
                    self?.currentUserId = userId
                }
            )
            .store(in: &cancellables)
    }
    
    // Sign in with email and password
    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        authService.signIn(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionStatus in
                    if case .failure = completionStatus {
                        // Handle error
                        self?.isAuthenticated = false
                        self?.isAnonymous = false
                        self?.currentUserId = nil
                        DispatchQueue.main.async {
                            completion(false)
                        }
                    }
                },
                receiveValue: { [weak self] userId in
                    self?.isAuthenticated = true
                    self?.isAnonymous = false
                    self?.currentUserId = userId
                    DispatchQueue.main.async {
                        completion(true)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Create account
    func createAccount(email: String, password: String, completion: @escaping (Bool) -> Void) {
        authService.createUser(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionStatus in
                    if case .failure = completionStatus {
                        // Handle error
                        self?.isAuthenticated = false
                        self?.isAnonymous = false
                        self?.currentUserId = nil
                        DispatchQueue.main.async {
                            completion(false)
                        }
                    }
                },
                receiveValue: { [weak self] userId in
                    self?.isAuthenticated = true
                    self?.isAnonymous = false
                    self?.currentUserId = userId
                    DispatchQueue.main.async {
                        completion(true)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Sign out
    func signOut() {
        authService.signOut()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] in
                    self?.isAuthenticated = false
                    self?.isAnonymous = true
                    self?.currentUserId = nil
                    self?.isPro = false
                    
                    // Clear widget data
                    WidgetDataManager.shared.clearWidgetData()
                }
            )
            .store(in: &cancellables)
    }
    
    // Upgrade anonymous account
    func upgradeAnonymousAccount(email: String, password: String, completion: @escaping (Bool) -> Void) {
        // For now, just sign in with new credentials
        signIn(email: email, password: password, completion: completion)
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme = "default"
    @Published var isDarkMode = false
    
    // Set theme preferences
    func setThemePreference(useSystemTheme: Bool, themeName: String) {
        if useSystemTheme {
            // Use system theme
            self.currentTheme = "default"
        } else {
            // Use custom theme
            self.currentTheme = themeName
            // Set dark mode based on theme name
            self.isDarkMode = themeName == "dark"
        }
    }
}
