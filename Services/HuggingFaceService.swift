import Foundation
import Combine
import SwiftUI

// Define local service errors - simpler approach to avoid import issues
enum ServiceError: Error {
    case missingAPIKey
    case networkError
    case serverError
    case rateLimitExceeded
    case invalidResponse
    case jsonParsingError
    case unknown(String)
}

class HuggingFaceService {
    // Default API key that can be used by all users
    private let defaultAPIKey = "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" // Replace with your actual API key
    
    // Free tier API key for anonymous users
    private let freeTierAPIKey = "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" // Insert your Hugging Face free tier API key here
    
    // Free tier models (smaller, efficient models suitable for the free tier)
    private let freeTierModels = [
        "google/gemma-2-2b-it",
        "microsoft/phi-2",
        "TinyLlama/TinyLlama-1.1B-Chat-v1.0",
        "mistralai/Mistral-7B-Instruct-v0.1"
    ]
    
    // Service configuration
    private var apiKey: String?
    private var model: String = "mistralai/Mistral-7B-Instruct-v0.2" // Default model
    
    // API endpoints
    private let baseURL = "https://api-inference.huggingface.co/models/"
    
    init() {
        // Set the default API key initially to ensure we always have a key
        self.apiKey = defaultAPIKey
        
        // Then check if there's a saved key
        if let savedKey = UserDefaults.standard.string(forKey: "huggingface_api_key"), !savedKey.isEmpty {
            self.apiKey = savedKey
        }
        
        // Load saved model if available
        if let savedModel = UserDefaults.standard.string(forKey: "huggingface_model") {
            self.model = savedModel
        }
    }
    
    // Set API key and save to UserDefaults
    func setAPIKey(_ key: String) {
        // Trim the key to avoid whitespace issues
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedKey.isEmpty {
            self.apiKey = trimmedKey
            UserDefaults.standard.set(trimmedKey, forKey: "huggingface_api_key")
        } else {
            // If empty key is provided, fall back to default
            useDefaultAPIKey()
        }
    }
    
    // Use the default API key provided by the app
    func useDefaultAPIKey() {
        self.apiKey = defaultAPIKey
        // We don't save the default key to UserDefaults to avoid exposing it
        #if DEBUG
        // Only print in debug builds and only when the key actually changes
        if self.apiKey != defaultAPIKey {
            print("Using default HuggingFace API key")
        }
        #endif
    }
    
    // Use the free tier API key for anonymous users
    func useFreeTierAPIKey() {
        self.apiKey = freeTierAPIKey
        #if DEBUG
        // Only print in debug builds and only when the key actually changes
        if self.apiKey != freeTierAPIKey {
            print("Using free tier HuggingFace API key")
        }
        #endif
    }
    
    // Set model and save to UserDefaults
    func setModel(_ modelName: String) {
        self.model = modelName
        UserDefaults.standard.set(modelName, forKey: "huggingface_model")
    }
    
    // Check if a model is available for the free tier
    func isModelAvailableForFreeTier(_ modelName: String) -> Bool {
        return freeTierModels.contains(modelName)
    }
    
    // Create therapy response using Hugging Face API
    func getTherapyResponse(for userInput: String) -> AnyPublisher<String, Error> {
        // Ensure we have an API key
        guard let apiKey = self.apiKey, !apiKey.isEmpty else {
            print("Missing HuggingFace API key, falling back to default key")
            // Try to use default key as a fallback
            self.apiKey = defaultAPIKey
            
            // If we still don't have a key, return error
            guard defaultAPIKey.count > 0 else {
                return Fail(error: ServiceError.missingAPIKey).eraseToAnyPublisher()
            }
            
            // Continue with default key
            return getTherapyResponse(for: userInput)
        }
        
        // Construct request URL
        guard let url = URL(string: baseURL + model) else {
            return Fail(error: ServiceError.unknown("Invalid URL")).eraseToAnyPublisher()
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build the appropriate payload based on model
        let promptText = """
        You are a professional therapist responding to someone who needs emotional support. Provide a compassionate, helpful response that:
        1. Validates their feelings
        2. Offers specific practical advice or coping strategies
        3. Suggests ways to improve their overall wellbeing
        
        IMPORTANT: NEVER respond in first-person as if you are the one experiencing their problems. Do NOT say "I feel" or talk about your own experiences. Always respond as a therapist speaking directly to the person needing help.
        
        Keep your response supportive, solution-focused, and encouraging. Offer at least one practical suggestion they can try immediately.
        """
        
        let payload: [String: Any]
        if model.lowercased().contains("mistral") || model.lowercased().contains("mixtral") {
            payload = [
                "inputs": promptText + "\n\n" + userInput,
                "parameters": [
                    "max_new_tokens": 1000,
                    "temperature": 0.7,
                    "top_p": 0.9,
                    "do_sample": true
                ]
            ]
        } else if model.lowercased().contains("llama") || model.lowercased().contains("gemma") {
            payload = [
                "inputs": promptText + "\n\n" + userInput,
                "parameters": [
                    "max_new_tokens": 600,
                    "temperature": 0.7,
                    "top_p": 0.9,
                    "do_sample": true
                ]
            ]
        } else if model.lowercased().contains("falcon") {
            payload = [
                "inputs": promptText + "\n\n" + userInput,
                "parameters": [
                    "max_new_tokens": 600,
                    "temperature": 0.7,
                    "top_p": 0.9,
                    "do_sample": true
                ]
            ]
        } else {
            // Generic payload for other models
            payload = [
                "inputs": promptText + "\n\n" + userInput,
                "parameters": [
                    "max_new_tokens": 600,
                    "temperature": 0.7,
                    "return_full_text": false
                ]
            ]
        }
        
        // Serialize the payload
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            return Fail(error: ServiceError.jsonParsingError).eraseToAnyPublisher()
        }
        
        // Create the network request
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ServiceError.invalidResponse
                }
                
                // Check response status code
                switch httpResponse.statusCode {
                case 200:
                    return data
                case 401:
                    throw ServiceError.missingAPIKey
                case 429:
                    throw ServiceError.rateLimitExceeded
                case 500...599:
                    throw ServiceError.serverError
                default:
                    throw ServiceError.unknown("HTTP status code: \(httpResponse.statusCode)")
                }
            }
            .tryMap { (data: Data) -> String in
                // Parse JSON response
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    // Check if response is directly an array
                    if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                       let firstItem = jsonArray.first,
                       let generatedText = firstItem["generated_text"] as? String {
                        return self.cleanResponse(generatedText, userInput: userInput)
                    }
                    
                    // Try to parse the response as a string
                    if let responseString = String(data: data, encoding: .utf8) {
                        return self.cleanResponse(responseString, userInput: userInput)
                    }
                    
                    throw ServiceError.jsonParsingError
                }
                
                // Check if the output is directly available as a string
                if let output = json["output"] as? String {
                    return self.cleanResponse(output, userInput: userInput)
                }
                
                // Check if the output is available in an array
                if let outputs = json["outputs"] as? [String], let firstOutput = outputs.first {
                    return self.cleanResponse(firstOutput, userInput: userInput)
                }
                
                // Check if output is a dictionary with generated_text
                if let output = json["output"] as? [String: Any], 
                   let generatedText = output["generated_text"] as? String {
                    return self.cleanResponse(generatedText, userInput: userInput)
                }
                
                // Check if output is an array of dictionaries
                if let output = json["output"] as? [[String: Any]], 
                   let firstOutput = output.first,
                   let generatedText = firstOutput["generated_text"] as? String {
                    return self.cleanResponse(generatedText, userInput: userInput)
                }
                
                throw ServiceError.jsonParsingError
            }
            .mapError { error -> Error in
                if let apiError = error as? ServiceError {
                    return apiError
                }
                return ServiceError.unknown(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    // Clean the response to remove any artifacts, prompt text, or repeated user input
    private func cleanResponse(_ text: String, userInput: String) -> String {
        var cleanedText = text
        
        // First, try to extract just the response part by removing the prompt and user input
        if let responseStart = cleanedText.range(of: userInput)?.upperBound {
            cleanedText = String(cleanedText[responseStart...])
        }
        
        // Remove role labels like "Therapist:" or "AI:"
        let roleLabelPatterns = [
            "^Therapist:\\s*", 
            "^AI:\\s*", 
            "^Assistant:\\s*", 
            "^Counselor:\\s*",
            "^Response:\\s*",
            "^Message:\\s*"
        ]
        
        for pattern in roleLabelPatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .anchorsMatchLines])
            let range = NSRange(location: 0, length: cleanedText.utf16.count)
            cleanedText = regex?.stringByReplacingMatches(in: cleanedText, options: [], range: range, withTemplate: "") ?? cleanedText
        }
        
        // MAJOR ENHANCEMENT: Check if there's a genuine therapeutic response after some inappropriate text
        // Look for common starting phrases of actual therapeutic responses
        let therapeuticStarterPhrases = [
            "I'm sorry to hear", 
            "I'm really sorry", 
            "I understand",
            "It's understandable",
            "It sounds like",
            "It's normal to feel",
            "Your feelings are valid",
            "That must be difficult",
            "This sounds challenging",
            "It can be hard",
            "Thank you for sharing",
            "I appreciate you sharing",
            "Feeling this way is"
        ]
        
        // Check if any of these phrases appear and use only the content from there
        for phrase in therapeuticStarterPhrases {
            if let actualResponseStart = cleanedText.range(of: phrase, options: [.caseInsensitive]) {
                let newStart = cleanedText.index(actualResponseStart.lowerBound, offsetBy: 0)
                cleanedText = String(cleanedText[newStart...])
                break
            }
        }
        
        // Comprehensive check for inappropriate first-person narratives that indicate the AI is talking about itself
        let firstPersonNarrativeIndicators = [
            "in my family", "my parents", "growing up, I", "in my experience", "in my life",
            "my childhood", "my relationship with", "my spouse", "my partner", "with my",
            "my mother", "my father", "my sibling", "my friend", "in my case", 
            "I've been trying", "I've tried", "I feel like", "I'm the only one", "I went through",
            "when I was", "like I'm", "been trying to", "ends in arguments", "no one seems to",
            "we hardly spend", "I feel unapp", "like I'm just", "afterthought in", "my girlfriend",
            "my boyfriend", "my relationship is", "we don't", "I don't get", "hardly see each"
        ]
        
        // Check for ANY first-person indicators in the FIRST TWO SENTENCES
        // Extract first two sentences
        let firstTwoSentencesRegex = try? NSRegularExpression(pattern: "^[^.!?]*[.!?]\\s*[^.!?]*[.!?]", options: [])
        let range = NSRange(location: 0, length: cleanedText.utf16.count)
        
        if let match = firstTwoSentencesRegex?.firstMatch(in: cleanedText, options: [], range: range),
           let matchRange = Range(match.range, in: cleanedText) {
            let firstTwoSentences = String(cleanedText[matchRange])
            
            for indicator in firstPersonNarrativeIndicators {
                if firstTwoSentences.lowercased().contains(indicator.lowercased()) {
                    // This is likely an inappropriate first-person narrative at the start
                    // Check if there's a valid response later in the text
                    if let actualTherapeuticStart = findTherapeuticStartingPoint(in: cleanedText) {
                        cleanedText = actualTherapeuticStart
                    } else {
                        // If no valid response found, use fallback
                        return generateTherapeuticFallback(for: userInput)
                    }
                    break
                }
            }
        }
        
        // Aggressively remove prompt and instruction texts
        let instructionPatterns = [
            // Original patterns
            "Send a warm, caring message",
            "to someone going through a difficult time",
            "You are a compassionate therapist",
            "You are a professional therapist",
            "responding to someone who needs emotional support",
            "Provide a compassionate, helpful response",
            "Validates their feelings",
            "Offers specific practical advice",
            "Suggests ways to improve",
            "IMPORTANT: NEVER respond in first-person",
            "Do NOT say",
            "Always respond as a therapist",
            "Keep your response supportive",
            "Offer at least one practical suggestion",
            // Additional patterns to catch userside prompts
            "I'll respond with compassion",
            "Let me respond with",
            "I'll provide a supportive response",
            "Here's a supportive message",
            "Here's a compassionate response",
            "Here's my response",
            "As a supportive friend",
            "As a caring person",
            "As a therapist would say",
            "Offering support for",
            "Responding to your thought",
            "In response to your feelings about",
            "Responding compassionately",
            "Understanding your feelings",
            // Common beginnings of meta-commentary
            "To address this concern",
            "To respond to this",
            "In this response",
            "For someone feeling",
            "For a person who",
            "This person is",
            "The person is",
            "It sounds like the person",
            "The message indicates",
            "Based on what you've shared",
            "Based on your message",
            // Any repeated user input
            userInput
        ]
        
        // Apply more aggressive pattern removal
        for pattern in instructionPatterns {
            if !pattern.isEmpty {
                cleanedText = cleanedText.replacingOccurrences(of: pattern, with: "", options: [.caseInsensitive])
            }
        }
        
        // Remove markdown formatting
        let markdownPatterns = [
            "\\*\\*(.+?)\\*\\*", // Bold
            "\\*(.+?)\\*",       // Italic
            "^#\\s+(.+)$",       // Heading
            "^>\\s+(.+)$",       // Blockquote
            "```[\\s\\S]*?```",  // Code blocks
            "`([^`]+)`",         // Inline code
            "^\\d+\\.\\s+(.+)$", // Ordered list
            "^-\\s+(.+)$",       // Unordered list
            "\\[(.+?)\\]\\(.+?\\)" // Links
        ]
        
        for pattern in markdownPatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
            let range = NSRange(location: 0, length: cleanedText.utf16.count)
            cleanedText = regex?.stringByReplacingMatches(in: cleanedText, options: [], range: range, withTemplate: "$1") ?? cleanedText
        }
        
        // Remove instructional patterns - expanded to catch any remaining instructions
        let promptInstructionPatterns = [
            "ignore previous instructions",
            "I am a language model",
            "This is a roleplay",
            "as an AI",
            "as a therapist",
            "ai assistant",
            "respond directly to the person's thoughts",
            "the person shared",
            "Your message should be",
            "respond with warmth",
            "send them a brief",
            "they just said",
            "genuine conversation",
            "I'm supposed to",
            "should validate",
            "brief message",
            "message of support",
            "authentic response",
            "write as if",
            "having a difficult moment",
            "send a warm",
            "caring message",
            "someone going through",
            "difficult time",
            "Here's my response:",
            "Responding to:",
            "warm and empathetic",
            "warm and caring",
            "going through a hard time",
            "to show empathy",
            "empathetically",
            "supportively"
        ]
        
        for pattern in promptInstructionPatterns {
            cleanedText = cleanedText.replacingOccurrences(of: pattern, with: "", options: [.caseInsensitive])
        }
        
        // One final check for problematic responses after all cleaning
        // If the response still has first-person narrative tone, replace with fallback
        if cleanedText.matches("\\b[Ii]'ve been\\b") || 
           cleanedText.matches("\\bin my\\b") || 
           (cleanedText.matches("\\bmy\\b") && cleanedText.matches("\\bfamily\\b")) {
            return generateTherapeuticFallback(for: userInput)
        }
        
        // Final cleaning patterns to catch remaining instruction text
        let finalCleaningPatterns = [
            "brief message",
            "message of support",
            "authentic response",
            "respond directly",
            "personal message",
            "validate their feelings",
            "support them through",
            "warm and empathetic",
            "caring and supportive",
            "kind message",
            "empathetic response",
            "supportive message",
            "responding to your",
            "message for someone",
            "my message to you"
        ]
        
        for pattern in finalCleaningPatterns {
            let regex = try? NSRegularExpression(pattern: "[^.!?]*\(pattern)[^.!?]*[.!?]", options: [.caseInsensitive])
            let range = NSRange(location: 0, length: cleanedText.utf16.count)
            cleanedText = regex?.stringByReplacingMatches(in: cleanedText, options: [], range: range, withTemplate: "") ?? cleanedText
        }
        
        // Final validation step - remove lines that appear to be meta-commentary or instructions
        let metaCommentaryIndicators = [
            "I will", "I should", "I'm going to", "My approach", "My response",
            "I need to", "I'm meant to", "I'd like to", "In response to",
            "As requested", "Here's my", "Here is my", "In this response",
            "To respond to", "To address", "I'll offer", "I'll provide",
            "For someone who", "For a person who", "The person is", "This person is",
            "It seems the", "It appears the", "From what I", "Based on what"
        ]
        
        let lines = cleanedText.components(separatedBy: .newlines)
        let filteredLines = lines.filter { line in
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return !metaCommentaryIndicators.contains { indicator in
                trimmedLine.lowercased().hasPrefix(indicator.lowercased())
            }
        }
        
        cleanedText = filteredLines.joined(separator: " ") // Join with spaces instead of newlines for shorter responses
        
        // Remove common greeting patterns at the start of the text
        let greetingPatterns = ["Hello,", "Hi,", "Hey,", "Hello.", "Hi.", "Hey."]
        for greeting in greetingPatterns {
            if cleanedText.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(greeting) {
                cleanedText = cleanedText.replacingOccurrences(of: greeting, with: "")
                break
            }
        }
        
        // Clean up double spaces caused by content removal
        while cleanedText.contains("  ") {
            cleanedText = cleanedText.replacingOccurrences(of: "  ", with: " ")
        }
        
        // Use shorter conversation starters
        let starters = [
            "I understand.",
            "That's tough.",
            "I hear you.",
            "You're not alone.",
            "That's valid.",
            "It's okay to feel that way."
        ]
        
        // Only add a starter if the response doesn't already have a conversational tone
        var hasConversationalStarter = false
        for starter in starters {
            if cleanedText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasPrefix(starter.lowercased()) ||
               cleanedText.lowercased().contains("i'm sorry") ||
               cleanedText.lowercased().contains("i understand") {
                hasConversationalStarter = true
                break
            }
        }
        
        if !hasConversationalStarter && !cleanedText.isEmpty {
            let randomStarter = starters.randomElement() ?? "I hear you."
            cleanedText = "\(randomStarter) \(cleanedText)"
        }
        
        // Final trimming
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If somehow the response is empty, provide a short fallback
        if cleanedText.isEmpty {
            cleanedText = "I hear you. What you're feeling is valid. Take a deep breath - you've got this."
        }
        
        // Limit response to 1000 characters to ensure we have comprehensive responses
        if cleanedText.count > 1000 {
            // Find a good cutoff point at a sentence boundary
            let sentences = cleanedText.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            var finalResponse = ""
            
            for sentence in sentences {
                let potentialResponse = finalResponse + sentence + "."
                if potentialResponse.count <= 1000 {
                    finalResponse = potentialResponse
                } else {
                    break
                }
            }
            
            // If we didn't get any complete sentences, just truncate
            if finalResponse.isEmpty {
                let index = cleanedText.index(cleanedText.startIndex, offsetBy: min(990, cleanedText.count))
                finalResponse = String(cleanedText[..<index]) + "..."
            }
            
            cleanedText = finalResponse
        }
        
        // Final check to make sure we have a helpful response
        if cleanedText.isEmpty || cleanedText.count < 100 {
            return generateTherapeuticFallback(for: userInput)
        }
        
        return cleanedText
    }
    
    // Generate a high-quality therapeutic fallback response based on the user's input
    private func generateTherapeuticFallback(for userInput: String) -> String {
        // Different fallbacks based on common emotional concerns
        if userInput.lowercased().contains("misunderstood") {
            return "Feeling misunderstood can be deeply frustrating. It's common to feel isolated when others don't seem to grasp your perspective or needs. Try being specific about what understanding would look like for you - sometimes saying 'When you do X, I feel Y' can help others connect with your experience. Consider journaling your thoughts first to clarify them. Remember that you deserve to be heard, and there are people who will make the effort to understand you. In the meantime, be kind to yourself and acknowledge the validity of your feelings."
        } else if userInput.lowercased().contains("anxious") || userInput.lowercased().contains("anxiety") {
            return "When anxiety rises, try the 5-4-3-2-1 grounding technique: notice 5 things you can see, 4 things you can touch, 3 things you can hear, 2 things you can smell, and 1 thing you can taste. Deep breathing helps too - breathe in for 4 counts, hold for 2, and exhale for 6. Your feelings are valid, but remember that anxiety often magnifies concerns beyond their actual impact. Consider setting aside specific 'worry time' each day, allowing yourself to address concerns during that window while gently redirecting anxious thoughts at other times."
        } else if userInput.lowercased().contains("sad") || userInput.lowercased().contains("depress") {
            return "I'm sorry you're feeling this way. Your emotions are valid, and it takes courage to acknowledge them. Try to engage in one small activity that has brought you joy in the past, even if it doesn't seem appealing now. Physical movement, even just a short walk, can help shift your brain chemistry. Connection matters too - reach out to someone supportive, even with just a simple message. Be gentle with yourself and remember that emotions are temporary states, not permanent conditions. Consider simple self-care practices like adequate rest, hydration, and nutrition."
        } else if userInput.lowercased().contains("angry") || userInput.lowercased().contains("frustrat") {
            return "Your frustration is completely understandable. When anger builds up, try taking a brief 'timeout' - step away and focus on your breathing for a few minutes. Physical release can help too - even something as simple as squeezing a stress ball or taking a brisk walk. Try to identify the primary emotion beneath the anger, as it's often covering hurt, fear, or disappointment. Writing down your thoughts can help process these feelings. Remember that your anger is giving you important information about your boundaries and needs."
        } else {
            return "What you're feeling is completely valid. When emotions feel overwhelming, try taking a few deep breaths and grounding yourself in the present moment. Small self-care steps can make a difference - perhaps a short walk, a cup of tea, or connecting with someone who makes you feel safe. Consider writing down your thoughts to gain clarity, or try the 'opposite action' technique: identify what your emotion urges you to do, then consider doing the opposite. Remember that seeking support is a sign of strength, not weakness. What small step might help you feel a bit better today?"
        }
    }
    
    // New helper function to find where the actual therapeutic response starts
    private func findTherapeuticStartingPoint(in text: String) -> String? {
        // Common starting phrases and patterns for legitimate therapeutic responses
        let therapeuticStartPatterns = [
            "I'm sorry to hear", 
            "I'm really sorry", 
            "I understand",
            "It's understandable",
            "It sounds like",
            "It's normal to feel",
            "Your feelings are valid",
            "That must be difficult",
            "This sounds challenging",
            "It can be hard",
            "Thank you for sharing",
            "I appreciate you sharing",
            "Feeling this way is",
            // Additional therapeutic sentence starters
            "It's important to",
            "One thing to consider",
            "You might find it helpful",
            "Consider trying",
            "A helpful approach",
            "Many people experience",
            "You're not alone in",
            "This is a common",
            "Relationships can be",
            "Feeling unloved is"
        ]
        
        for pattern in therapeuticStartPatterns {
            if let range = text.range(of: pattern, options: [.caseInsensitive]) {
                return String(text[range.lowerBound...])
            }
        }
        
        // Try to find sentences that look therapeutic by checking for second-person perspective
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        for (index, sentence) in sentences.enumerated() {
            let cleanSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanSentence.isEmpty { continue }
            
            // Check if sentence has therapeutic indicators (you/your) and lacks first-person indicators (I/my)
            if (cleanSentence.lowercased().contains("you") || cleanSentence.lowercased().contains("your")) &&
               !cleanSentence.lowercased().contains(" my ") && 
               !cleanSentence.lowercased().contains(" i ") {
                
                // Found a potential therapeutic sentence - use everything from here
                if index < sentences.count - 1 {
                    let remainingSentences = sentences[index...].joined(separator: ".")
                    return remainingSentences.trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    return cleanSentence
                }
            }
        }
        
        return nil
    }
}

// Response model for Hugging Face API
struct HuggingFaceResponse: Decodable {
    let generatedText: String
    
    enum CodingKeys: String, CodingKey {
        case generatedText = "generated_text"
    }
}

// Extension to add regex matching to String
extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }
}

// Define the available Hugging Face models
enum HuggingFaceModels: String, CaseIterable {
    case mistral7b = "mistralai/Mistral-7B-Instruct-v0.2"
    case llama3 = "meta-llama/Llama-3-8b-chat-hf"
    case gemma = "google/gemma-7b-it"
    case mistralTiny = "mistralai/Mistral-7B-Instruct-v0.1"
    case falcon = "tiiuae/falcon-7b-instruct"
    
    var displayName: String {
        switch self {
        case .mistral7b:
            return "Mistral 7B (Recommended)"
        case .llama3:
            return "Llama 3 (8B)"
        case .gemma:
            return "Gemma (7B)"
        case .mistralTiny:
            return "Mistral Tiny"
        case .falcon:
            return "Falcon 7B"
        }
    }
} 
