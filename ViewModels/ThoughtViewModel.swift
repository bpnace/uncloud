import Foundation
import SwiftUI
import SwiftData
import Combine

class ThoughtViewModel: ObservableObject {
    // Dependencies
    private let gptService: GPTService
    private let huggingFaceService: HuggingFaceService
    private var cancellables = Set<AnyCancellable>()
    
    // Usage manager for tracking limits - will be injected
    var usageManager: UsageManager?
    
    // AI provider selection - always use Hugging Face now
    private var selectedAIProvider: String = "huggingface"
    
    // Published properties for UI binding
    @Published var inputText: String = ""
    @Published var response: String = ""
    @Published var isProcessing: Bool = false
    @Published var error: String? = nil
    @Published var showError: Bool = false
    @Published var characterLimit: Int = 100
    @Published var limitReached: Bool = false
    
    // SwiftData context - will be injected
    var modelContext: ModelContext?
    
    // User info
    @Published var userId: String = ""
    var isAnonymous: Bool = true
    
    // Authentication state
    @Published var isAuthenticated: Bool = false
    
    // Current thought being processed
    private var currentThought: Thought? = nil
    
    // Conversation thread for the current thought
    @Published var conversationMessages: [ConversationMessage] = []
    
    // Data manager for persistence
    private let dataManager = DataManager.shared
    
    // Placeholder rotation for text input
    @Published var placeholderIndex: Int = 0
    private let placeholders = ["I feel...", "I think...", "I want..."]
    
    // Computed property to get the current placeholder
    var currentPlaceholder: String {
        return placeholders[placeholderIndex]
    }
    
    // Initialization with dependency injection
    init(gptService: GPTService = GPTService(), huggingFaceService: HuggingFaceService = HuggingFaceService()) {
        self.gptService = gptService
        self.huggingFaceService = huggingFaceService
        
        // Ensure Hugging Face service uses default API key
        self.huggingFaceService.useDefaultAPIKey()
        
        // Load settings if available
        loadSettings()
    }
    
    // Check for potential prompt injection in user input
    private func sanitizeInput(_ input: String) -> String {
        // List of potential prompt injection phrases to check for
        let promptInjectionPhrases = [
            "ignore previous instructions",
            "ignore prior instructions", 
            "disregard previous", 
            "as an AI", 
            "as an LLM",
            "prompt engineering",
            "system prompt",
            "you are a",
            "act as",
            "pretend to be",
            "new instructions",
            "override"
        ]
        
        // Check if input contains any suspicious phrases
        let lowercasedInput = input.lowercased()
        for phrase in promptInjectionPhrases {
            if lowercasedInput.contains(phrase) {
                // Replace the phrase with asterisks
                return "I'm feeling " + String(repeating: "*", count: phrase.count) + ". Can you help me process this emotion?"
            }
        }
        
        return input
    }
    
    // Process the thought and get AI response
    func processThought() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self.error = "Please enter a thought."
            self.showError = true
            return
        }
        
        // Check if user has reached their usage limit
        if let usageManager = usageManager, !usageManager.canRequestResponse() {
            self.limitReached = true
            return
        }
        
        isProcessing = true
        error = nil
        
        // Sanitize input to prevent prompt injection
        let sanitizedInput = sanitizeInput(inputText)
        
        // Create a new thought
        let thought = Thought(
            content: sanitizedInput,
            createdAt: Date(),
            userId: userId
        )
        
        // Save this as the current thought
        self.currentThought = thought
        
        // Always use Hugging Face for processing
        let responsePublisher = huggingFaceService.getTherapyResponse(for: sanitizedInput)
        
        responsePublisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.handleError(error)
                    }
                    self?.isProcessing = false
                },
                receiveValue: { [weak self] response in
                    self?.response = response
                    self?.saveThoughtWithResponse(response)
                    
                    // Increment usage counter
                    self?.usageManager?.incrementResponseCount()
                }
            )
            .store(in: &cancellables)
    }
    
    // Retry processing a thought after fixing API key
    private func retryProcessThought() {
        // Don't retry if there's no input
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isProcessing = true
        
        let responsePublisher = huggingFaceService.getTherapyResponse(for: inputText)
        
        responsePublisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.handleError(error)
                    }
                    self?.isProcessing = false
                },
                receiveValue: { [weak self] response in
                    self?.response = response
                    self?.saveThoughtWithResponse(response)
                    
                    // Increment usage counter
                    self?.usageManager?.incrementResponseCount()
                }
            )
            .store(in: &cancellables)
    }
    
    // Save thought to database
    private func saveThoughtWithResponse(_ response: String) {
        guard let thought = currentThought else { return }
        
        // Update the thought with the response
        thought.aiResponse = response
        thought.isProcessed = true
        
        // Add the AI response to the conversation thread
        thought.addAIResponse(response)
        
        // Update the conversation messages for the UI
        self.conversationMessages = thought.conversationThread
        
        // Save using the data manager
        dataManager.saveThought(thought)
        
        // Save for widget
        WidgetDataManager.shared.saveLatestThought(
            content: thought.content,
            response: response,
            createdAt: thought.createdAt
        )
    }
    
    // Process a reply to the current thought
    func processReply(reply: String) {
        guard let thought = currentThought, 
              !reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Check if user has reached their usage limit
        if let usageManager = usageManager, !usageManager.canRequestResponse() {
            self.limitReached = true
            return
        }
        
        isProcessing = true
        error = nil
        
        // Sanitize the reply
        let sanitizedReply = sanitizeInput(reply)
        
        // Add user reply to conversation thread
        thought.addUserReply(sanitizedReply)
        
        // Update UI conversation messages
        self.conversationMessages = thought.conversationThread
        
        // Get conversation context for better AI responses
        let context = buildConversationContext(from: thought.conversationThread)
        
        // Get AI response
        let responsePublisher = huggingFaceService.getTherapyResponse(for: context)
        
        responsePublisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.handleError(error)
                    }
                    self?.isProcessing = false
                },
                receiveValue: { [weak self] response in
                    // Add AI response to conversation
                    thought.addAIResponse(response)
                    
                    // Update the response in the UI
                    self?.response = response
                    
                    // Update UI conversation messages
                    self?.conversationMessages = thought.conversationThread
                    
                    // Save the updated thought
                    self?.dataManager.saveThought(thought)
                    
                    // Increment usage counter
                    self?.usageManager?.incrementResponseCount()
                }
            )
            .store(in: &cancellables)
    }
    
    // Build conversation context for the AI from the conversation thread
    private func buildConversationContext(from thread: [ConversationMessage]) -> String {
        // Limit to last 4 messages to prevent context overload
        let recentMessages = thread.suffix(min(thread.count, 4))
        
        // Instead of a complex conversation history, provide only the essential context
        // This format is less likely to be echoed back in the response
        var context = ""
        
        // Only include previous messages if there's more than one
        if recentMessages.count > 1 {
            // Get the latest user message
            if let latestMessage = recentMessages.last, latestMessage.isFromUser {
                // Just send the user's latest thought, which is cleaner and less likely to be echoed
                context = latestMessage.content
            } else {
                // Just in case the last message isn't from the user (shouldn't happen)
                if let lastUserMessage = recentMessages.last(where: { $0.isFromUser }) {
                    context = lastUserMessage.content
                }
            }
        } else if let firstMessage = recentMessages.first {
            // If it's the first message, just use it directly
            context = firstMessage.content
        }
        
        return context
    }
    
    // Clear the current thought
    func resetView() {
        inputText = ""
        response = ""
        currentThought = nil
        conversationMessages = []
        
        // Rotate to the next placeholder
        placeholderIndex = (placeholderIndex + 1) % placeholders.count
    }
    
    // Load settings including API keys and selected provider
    func loadSettings() {
        guard let context = modelContext else { return }
        dataManager.setModelContext(context)
        
        let descriptor = FetchDescriptor<AppSettings>()
        if let settings = try? context.fetch(descriptor).first {
            // Always use Hugging Face regardless of settings
            selectedAIProvider = "huggingface"
            settings.selectedAIProvider = "huggingface"
            
            // Load Hugging Face settings
            if settings.useDefaultHuggingFaceKey {
                huggingFaceService.useDefaultAPIKey()
            } else if let apiKey = settings.customHuggingFaceKey, !apiKey.isEmpty {
                huggingFaceService.setAPIKey(apiKey)
            } else {
                // If no custom key and not using default, fall back to default
                huggingFaceService.useDefaultAPIKey()
                settings.useDefaultHuggingFaceKey = true
            }
            
            huggingFaceService.setModel(settings.selectedHuggingFaceModel)
            
            try? context.save()
        } else {
            // If no settings exist, make sure to use default API key
            huggingFaceService.useDefaultAPIKey()
        }
    }
    
    // Handle errors
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .missingAPIKey:
                self.error = "Missing API key. Please check your settings."
            case .networkError:
                self.error = "Network error. Please check your connection."
            case .serverError:
                self.error = "Server error. Please try again later."
            case .rateLimitExceeded:
                self.error = "Rate limit exceeded. Please try again later."
            case .invalidResponse:
                self.error = "Invalid response received. Please try again."
            case .jsonParsingError:
                self.error = "Error processing response. Please try again."
            case .unknown(let message):
                self.error = "Error: \(message)"
            }
        } else if let serviceError = error as? ServiceError {
            switch serviceError {
            case .missingAPIKey:
                self.error = "Missing API key. Please check your settings."
                // Try with default API key
                huggingFaceService.useDefaultAPIKey()
                self.retryProcessThought()
                return
            case .networkError:
                self.error = "Network error. Please check your connection."
            case .serverError:
                self.error = "Server error. Please try again later."
            case .rateLimitExceeded:
                self.error = "Rate limit exceeded. Please try again later."
            case .invalidResponse:
                self.error = "Invalid response received. Please try again."
            case .jsonParsingError:
                self.error = "Error processing response. Please try again."
            case .unknown(let message):
                self.error = "Error: \(message)"
            }
        } else {
            self.error = "An unexpected error occurred: \(error.localizedDescription)"
        }
        self.showError = true
    }
    
    // Helper to get character count
    var characterCount: Int {
        return inputText.count
    }
    
    // Check if the thought is within character limit
    var isWithinCharacterLimit: Bool {
        return characterCount <= characterLimit
    }
    
    // Check if the thought can be submitted
    var canSubmit: Bool {
        // Add usage limit check to canSubmit
        let withinUsageLimit = usageManager?.canRequestResponse() ?? true
        return !inputText.isEmpty && !isProcessing && isWithinCharacterLimit && withinUsageLimit
    }
    
    // Load API key from settings
    func loadAPIKeyFromSettings() {
        loadSettings()
    }
    
    func setAuthentication(isAuthenticated: Bool, userId: String, isAnonymous: Bool = true) {
        self.isAuthenticated = isAuthenticated
        self.userId = userId
        self.isAnonymous = isAnonymous
        
        // Update authentication state in the data manager
        dataManager.setAuthState(isAnonymous: !isAuthenticated || isAnonymous, userId: userId)
        
        // Sync data if authenticated
        if isAuthenticated && !isAnonymous {
            dataManager.syncThoughts {
                // Completed sync
            }
        }
    }
    
    // Clean up expired thoughts (for anonymous users)
    func cleanupExpiredThoughts() async {
        await dataManager.cleanupExpiredThoughts()
    }
} 