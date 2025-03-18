import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var usageManager: UsageManager
    
    @Binding var selectedTab: Int
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var appSettings: [AppSettings]
    
    // OpenAI settings (kept for backend compatibility, hidden from user)
    @State private var openAIApiKey: String = ""
    @State private var showOpenAIApiKey: Bool = false
    @State private var selectedOpenAIModel: String = "gpt-3.5-turbo"
    @State private var showOpenAIApiKeySaved: Bool = false
    @State private var showOpenAIModelSaved: Bool = false
    
    // HuggingFace settings
    @State private var huggingFaceApiKey: String = ""
    @State private var showHuggingFaceApiKey: Bool = false
    @State private var selectedHuggingFaceModel: String = "google/gemma-2-2b-it"
    @State private var showHuggingFaceApiKeySaved: Bool = false
    @State private var showHuggingFaceModelSaved: Bool = false
    @State private var useDefaultApiKey: Bool = true
    
    // Common settings
    @State private var selectedAIProvider: String = "huggingface" // Default to Hugging Face now
    @State private var showSignInSheet: Bool = false
    @State private var showSubscriptionView: Bool = false
    @State private var notificationsEnabled: Bool = false
    @State private var privacyModeEnabled: Bool = false
    @State private var useSystemTheme: Bool = true
    @State private var selectedTheme: String = "default"
    @State private var showDeleteConfirmation: Bool = false
    @State private var showResetConfirmation: Bool = false
    @FocusState private var isApiKeyFieldFocused: Bool
    
    // Service instances
    private let gptService = GPTService()
    private let huggingFaceService = HuggingFaceService()
    
    // Available OpenAI models (kept for backend compatibility)
    private let availableOpenAIModels = [
        "gpt-4o",
        "gpt-4o-mini",
        "gpt-3.5-turbo"
    ]
    
    // Available Hugging Face models
    private let availableHuggingFaceModels = [
        "google/gemma-2-2b-it",
        "meta-llama/Meta-Llama-3.1-8B-Instruct",
        "microsoft/phi-4",
        "Qwen/Qwen2.5-7B-Instruct"
    ]
    
    // Compute models available for the current user tier
    private var availableModelsForCurrentUser: [String] {
        if authManager.isAnonymous {
            // Filter to only include free tier models for anonymous users
            return availableHuggingFaceModels.filter { huggingFaceService.isModelAvailableForFreeTier($0) }
        } else {
            // All models available for registered users
            return availableHuggingFaceModels
        }
    }
    
    // Initializer with default parameter for previews
    init(selectedTab: Binding<Int> = .constant(0)) {
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationView {
            List {
                // Account section - always active
                Section(header: Text("Account")) {
                    if authManager.isAuthenticated {
                        // Logged in user
                        Text("Signed in" + (authManager.isAnonymous ? " (Anonymous)" : " as \(authManager.currentUserId ?? "User")"))
                            .foregroundColor(.secondary)
                        
                        if authManager.isAnonymous {
                            Button("Upgrade to Pro Account") {
                                showSubscriptionView = true
                            }
                            .foregroundColor(.blue)
                        }
                        
                        if !authManager.isAnonymous {
                            // Only show sign out for non-anonymous users
                            Button("Sign Out") {
                                authManager.signOut()
                            }
                            .foregroundColor(.red)
                        } else {
                            // For anonymous users, also show login option
                            Button("Log In / Create Account") {
                                showSignInSheet = true
                            }
                            .foregroundColor(.green)
                        }
                    } else {
                        // Not logged in
                        Button("Sign In") {
                            showSignInSheet = true
                        }
                        .foregroundColor(.blue)
                        
                        Button("Continue as Guest") {
                            // This will simply dismiss and go back to ThoughtCaptureView
                            // No action needed as the user is already in guest mode
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                // For anonymous users, show a section explaining locked features
                if authManager.isAnonymous {
                    Section {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.orange)
                            Text("Create an account to access all settings")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // AI Model Settings section
                Section(header: SettingSectionHeader(title: "AI Model Settings", requiresAccount: authManager.isAnonymous)) {
                    Picker("AI Model", selection: $selectedHuggingFaceModel) {
                        ForEach(availableModelsForCurrentUser, id: \.self) { model in
                            Text(model)
                        }
                    }
                    .onChange(of: selectedHuggingFaceModel) { _, newValue in
                        saveHuggingFaceModelSelection()
                    }
                    
                    if showHuggingFaceModelSaved {
                        Text("Model selection saved")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    
                    Toggle("Use App's API Key", isOn: $useDefaultApiKey)
                        .onChange(of: useDefaultApiKey) { _, newValue in
                            if newValue {
                                // Use default API key
                                huggingFaceService.useDefaultAPIKey()
                                if let settings = appSettings.first {
                                    settings.useDefaultHuggingFaceKey = true
                                    try? modelContext.save()
                                }
                            }
                        }
                    
                    if !useDefaultApiKey {
                        HStack {
                            if showHuggingFaceApiKey {
                                TextField("Your Hugging Face API Key", text: $huggingFaceApiKey)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .focused($isApiKeyFieldFocused)
                            } else {
                                SecureField("Your Hugging Face API Key", text: $huggingFaceApiKey)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .focused($isApiKeyFieldFocused)
                            }
                            
                            Button(action: {
                                showHuggingFaceApiKey.toggle()
                            }) {
                                Image(systemName: showHuggingFaceApiKey ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button("Save API Key") {
                            isApiKeyFieldFocused = false
                            saveHuggingFaceApiKey()
                        }
                        .disabled(huggingFaceApiKey.isEmpty)
                        
                        if showHuggingFaceApiKeySaved {
                            Text("API key saved successfully")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        
                        Text("Your API key is stored securely on this device only")
                            .font(.caption)
                        
                        Link("Get a Free Hugging Face API Key", destination: URL(string: "https://huggingface.co/settings/tokens")!)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .disabled(authManager.isAnonymous)
                .opacity(authManager.isAnonymous ? 0.6 : 1)
                
                Section(header: SettingSectionHeader(title: "Appearance", requiresAccount: authManager.isAnonymous)) {
                    Toggle("Use System Theme", isOn: $useSystemTheme)
                        .onChange(of: useSystemTheme) { _, isEnabled in
                            saveThemeSettings()
                        }
                    
                    if !useSystemTheme {
                        Picker("Theme", selection: $selectedTheme) {
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedTheme) { _, newTheme in
                            saveThemeSettings()
                        }
                    }
                }
                .disabled(authManager.isAnonymous)
                .opacity(authManager.isAnonymous ? 0.6 : 1)
                
                Section(header: SettingSectionHeader(title: "Privacy", requiresAccount: authManager.isAnonymous)) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    
                    Toggle("Privacy Mode (Offline Only)", isOn: $privacyModeEnabled)
                    
                    Text("Privacy Mode stores all data locally and disables cloud features")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Delete All My Data") {
                        showDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                }
                .disabled(authManager.isAnonymous)
                .opacity(authManager.isAnonymous ? 0.6 : 1)
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appSettings.first?.appVersion ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: Text("Privacy Policy - Coming Soon")) {
                        Text("Privacy Policy")
                    }
                    
                    NavigationLink(destination: Text("Terms of Service - Coming Soon")) {
                        Text("Terms of Service")
                    }
                    
                    NavigationLink(destination: Text("Data Practices - Coming Soon")) {
                        Text("Data Practices")
                    }
                    
                    Text("This app is not a substitute for professional therapy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                // About section should remain active for all users
                
                #if DEBUG
                Section(header: Text("Developer Tools")) {
                    Button(action: {
                        // Direct reset without confirmation for better reliability
                        usageManager.devReset()
                        
                        // Provide haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        // Simple dismiss to avoid complex transitions
                        dismiss()
                    }) {
                        Label("Reset Usage Counter (Dev)", systemImage: "hammer.fill")
                    }
                    .foregroundColor(.blue)
                }
                #endif
            }
            .navigationTitle("Settings")
            .onAppear {
                // Create settings if it doesn't exist
                if appSettings.isEmpty {
                    let newSettings = AppSettings()
                    newSettings.selectedAIProvider = "huggingface" // Always use Hugging Face
                    newSettings.useDefaultHuggingFaceKey = true // Default to using the app's key
                    modelContext.insert(newSettings)
                    try? modelContext.save()
                }
                
                // Load settings
                if let settings = appSettings.first {
                    useSystemTheme = settings.useSystemTheme
                    selectedTheme = settings.colorTheme
                    notificationsEnabled = settings.dailyReminderEnabled
                    privacyModeEnabled = settings.dataRetentionPeriodDays == 0
                    
                    // Always use Hugging Face
                    selectedAIProvider = "huggingface"
                    settings.selectedAIProvider = "huggingface"
                    
                    // Load Hugging Face settings
                    huggingFaceApiKey = settings.customHuggingFaceKey ?? ""
                    selectedHuggingFaceModel = settings.selectedHuggingFaceModel
                    useDefaultApiKey = settings.useDefaultHuggingFaceKey
                    
                    try? modelContext.save()
                }
                
                // Ensure Hugging Face service is properly initialized
                if useDefaultApiKey {
                    huggingFaceService.useDefaultAPIKey()
                }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete All Data?"),
                    message: Text("This will permanently erase all your thoughts and journal entries. This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        // Will implement delete functionality
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showSignInSheet) {
                SignInView()
                    .environmentObject(authManager)
                    .environmentObject(usageManager)
            }
            .sheet(isPresented: $showSubscriptionView) {
                SubscriptionView()
                    .environmentObject(authManager)
                    .environmentObject(usageManager)
            }
        }
    }
    
    // Function to save AI provider selection (always huggingface now)
    private func saveAIProviderSelection() {
        // Save AI provider to AppSettings model
        if let settings = appSettings.first {
            settings.selectedAIProvider = "huggingface"
            try? modelContext.save()
        }
    }
    
    // Function to save OpenAI API key (kept for backend compatibility)
    private func saveOpenAIApiKey() {
        // Save the API key to the GPTService
        gptService.setAPIKey(openAIApiKey)
        
        // Save to AppSettings model
        if let settings = appSettings.first {
            settings.customOpenAIKey = openAIApiKey
            settings.apiKeySet = !openAIApiKey.isEmpty
            try? modelContext.save()
        }
    }
    
    // Function to save OpenAI model selection (kept for backend compatibility)
    private func saveOpenAIModelSelection() {
        // Save model selection to AppSettings model
        if let settings = appSettings.first {
            settings.selectedOpenAIModel = selectedOpenAIModel
            try? modelContext.save()
        }
        
        // Update GPTService with the selected model
        gptService.setModel(selectedOpenAIModel)
    }
    
    // Function to save Hugging Face API key
    private func saveHuggingFaceApiKey() {
        if useDefaultApiKey {
            huggingFaceService.useDefaultAPIKey()
            return
        }
        
        // Save the API key to the HuggingFaceService
        huggingFaceService.setAPIKey(huggingFaceApiKey)
        
        // Save to AppSettings model
        if let settings = appSettings.first {
            settings.customHuggingFaceKey = huggingFaceApiKey
            settings.huggingFaceAPIKeySet = !huggingFaceApiKey.isEmpty
            settings.useDefaultHuggingFaceKey = false
            try? modelContext.save()
        }
        
        // Show confirmation
        showHuggingFaceApiKeySaved = true
        
        // Hide confirmation after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showHuggingFaceApiKeySaved = false
        }
    }
    
    // Function to save Hugging Face model selection
    private func saveHuggingFaceModelSelection() {
        // Save model selection to AppSettings model
        if let settings = appSettings.first {
            settings.selectedHuggingFaceModel = selectedHuggingFaceModel
            try? modelContext.save()
        }
        
        // Update HuggingFaceService with the selected model
        huggingFaceService.setModel(selectedHuggingFaceModel)
        
        // Show confirmation
        showHuggingFaceModelSaved = true
        
        // Hide confirmation after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showHuggingFaceModelSaved = false
        }
    }
    
    // Function to save theme settings
    private func saveThemeSettings() {
        if let settings = appSettings.first {
            settings.useSystemTheme = useSystemTheme
            settings.colorTheme = selectedTheme
            try? modelContext.save()
        }
        
        // Update theme manager
        themeManager.setThemePreference(useSystemTheme: useSystemTheme, themeName: selectedTheme)
    }
}

// Custom section header that shows a lock icon for sections requiring an account
struct SettingSectionHeader: View {
    let title: String
    let requiresAccount: Bool
    
    var body: some View {
        HStack {
            Text(title)
            if requiresAccount {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
        .environmentObject(UsageManager())
        .modelContainer(for: AppSettings.self, inMemory: true)
} 