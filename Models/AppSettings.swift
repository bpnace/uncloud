import Foundation
import SwiftData

@Model
final class AppSettings {
    // App state
    var isFirstLaunch: Bool
    var lastUpdateCheckDate: Date?
    var appVersion: String
    
    // User preferences
    var colorTheme: String
    var useSystemTheme: Bool
    var fontScale: Double
    var hapticFeedbackEnabled: Bool
    
    // Notification settings
    var dailyReminderEnabled: Bool
    var dailyReminderTime: Date?
    var customNotificationMessages: [String]?
    
    // AI provider selection
    var selectedAIProvider: String
    
    // OpenAI settings
    var apiKeySet: Bool
    var customOpenAIKey: String?
    var selectedOpenAIModel: String
    
    // Hugging Face settings
    var huggingFaceAPIKeySet: Bool
    var customHuggingFaceKey: String?
    var selectedHuggingFaceModel: String
    var useDefaultHuggingFaceKey: Bool
    
    // Privacy
    var dataRetentionPeriodDays: Int
    var analyticsEnabled: Bool
    
    init(
        isFirstLaunch: Bool = true,
        lastUpdateCheckDate: Date? = nil,
        appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
        colorTheme: String = "default",
        useSystemTheme: Bool = true,
        fontScale: Double = 1.0,
        hapticFeedbackEnabled: Bool = true,
        dailyReminderEnabled: Bool = false,
        dailyReminderTime: Date? = nil,
        customNotificationMessages: [String]? = nil,
        selectedAIProvider: String = "huggingface",
        apiKeySet: Bool = false,
        customOpenAIKey: String? = nil,
        selectedOpenAIModel: String = "gpt-3.5-turbo",
        huggingFaceAPIKeySet: Bool = false,
        customHuggingFaceKey: String? = nil,
        selectedHuggingFaceModel: String = "google/gemma-2-2b-it",
        useDefaultHuggingFaceKey: Bool = true,
        dataRetentionPeriodDays: Int = 30,
        analyticsEnabled: Bool = true
    ) {
        self.isFirstLaunch = isFirstLaunch
        self.lastUpdateCheckDate = lastUpdateCheckDate
        self.appVersion = appVersion
        self.colorTheme = colorTheme
        self.useSystemTheme = useSystemTheme
        self.fontScale = fontScale
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.dailyReminderEnabled = dailyReminderEnabled
        self.dailyReminderTime = dailyReminderTime
        self.customNotificationMessages = customNotificationMessages
        self.selectedAIProvider = selectedAIProvider
        self.apiKeySet = apiKeySet
        self.customOpenAIKey = customOpenAIKey
        self.selectedOpenAIModel = selectedOpenAIModel
        self.huggingFaceAPIKeySet = huggingFaceAPIKeySet
        self.customHuggingFaceKey = customHuggingFaceKey
        self.selectedHuggingFaceModel = selectedHuggingFaceModel
        self.useDefaultHuggingFaceKey = useDefaultHuggingFaceKey
        self.dataRetentionPeriodDays = dataRetentionPeriodDays
        self.analyticsEnabled = analyticsEnabled
    }
} 