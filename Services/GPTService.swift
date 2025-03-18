import Foundation
import Combine

class GPTService {
    private var apiKey: String?
    private var modelName: String = "gpt-3.5-turbo"
    private let userDefaults = UserDefaults.standard
    private let apiKeyKey = "openai_api_key"
    private let modelNameKey = "openai_model_name"
    
    init() {
        // Try to load API key from UserDefaults
        apiKey = userDefaults.string(forKey: apiKeyKey)
        
        // Try to load model name from UserDefaults
        if let savedModel = userDefaults.string(forKey: modelNameKey) {
            modelName = savedModel
        }
    }
    
    func setAPIKey(_ key: String) {
        // Trim whitespace and newlines which might cause authentication errors
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        apiKey = trimmedKey
        userDefaults.set(trimmedKey, forKey: apiKeyKey)
    }
    
    func setModel(_ model: String) {
        modelName = model
        userDefaults.set(model, forKey: modelNameKey)
    }
    
    func getTherapyResponse(for thought: String) -> AnyPublisher<String, Error> {
        // Ensure API key exists
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            return Fail(error: APIError.missingAPIKey).eraseToAnyPublisher()
        }
        
        // OpenAI API endpoint
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Set up the model and messages
        let systemPrompt = """
        You are a warm, empathetic mental wellness guide with expertise in cognitive behavioral therapy techniques. When presented with a negative or intrusive thought:

        1. First, validate the person's emotions with genuine understanding - show you truly see their struggle and that their feelings are completely normal.
        2. Then, gently identify any cognitive distortions or thought patterns that might be intensifying their distress.
        3. Offer 1-2 specific, actionable coping strategies or perspective shifts they could try right now.
        4. Close with an empowering message that acknowledges their inner strength and resilience.

        Your response should be personal, warm, and conversational (5-6 sentences). Include specific examples or metaphors when helpful. Be honest that difficult emotions are part of being human, while offering hope and practical wisdom for moving through them.
        """
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": thought]
        ]
        
        let body: [String: Any] = [
            "model": modelName,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        let bodyData = try? JSONSerialization.data(withJSONObject: body)
        request.httpBody = bodyData
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.networkError
                }
                
                print("OpenAI API Response Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    // Log error response data to help diagnose the issue
                    if let errorResponse = String(data: data, encoding: .utf8) {
                        print("API Error Response: \(errorResponse)")
                    }
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw APIError.missingAPIKey
                case 429:
                    throw APIError.rateLimitExceeded
                case 500...599:
                    throw APIError.serverError
                default:
                    throw APIError.unknown("HTTP Error: \(httpResponse.statusCode)")
                }
            }
            .tryMap { data -> String in
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw APIError.jsonParsingError
                }
                
                // Log full response JSON for debugging (omit in production)
                print("OpenAI API Response: \(json)")
                
                // Check for error messages from OpenAI
                if let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    if message.contains("rate limit") {
                        throw APIError.rateLimitExceeded
                    } else {
                        throw APIError.unknown(message)
                    }
                }
                
                guard let choices = json["choices"] as? [[String: Any]],
                      let firstChoice = choices.first,
                      let message = firstChoice["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    throw APIError.invalidResponse
                }
                
                return content
            }
            .eraseToAnyPublisher()
    }
}

// Response models
struct OpenAIResponse: Decodable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
}

struct Choice: Decodable {
    let index: Int
    let message: Message
    let finishReason: String
    
    enum CodingKeys: String, CodingKey {
        case index
        case message
        case finishReason = "finish_reason"
    }
}

struct Message: Decodable {
    let role: String
    let content: String
}

struct Usage: Decodable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
} 