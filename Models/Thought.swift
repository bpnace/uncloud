import Foundation
import SwiftData

// ConversationMessage model for supporting conversation threads
struct ConversationMessage: Identifiable, Codable {
    var id: UUID = UUID()
    var content: String
    var isFromUser: Bool
    var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, content, isFromUser, timestamp
    }
}

@Model
final class Thought {
    // Basic properties
    var id: UUID
    var content: String
    var createdAt: Date
    var aiResponse: String?
    var isProcessed: Bool
    
    // For tracking expiry (24h for anonymous users)
    var expiresAt: Date?
    
    // For Pro users
    var tags: [String]?
    var mood: String?
    var isFavorite: Bool
    var isArchived: Bool
    
    // Relationship to user (if authenticated)
    var userId: String
    
    // New property to store conversation thread
    var conversationThread: [ConversationMessage] = []
    
    init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date(),
        aiResponse: String? = nil,
        isProcessed: Bool = false,
        expiresAt: Date? = Date().addingTimeInterval(24 * 60 * 60), // 24 hours by default
        tags: [String]? = nil,
        mood: String? = nil,
        isFavorite: Bool = false,
        isArchived: Bool = false,
        userId: String = "anonymous"
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.aiResponse = aiResponse
        self.isProcessed = isProcessed
        self.expiresAt = expiresAt
        self.tags = tags
        self.mood = mood
        self.isFavorite = isFavorite
        self.isArchived = isArchived
        self.userId = userId
        
        // Initialize conversation with the user's first message
        self.conversationThread = [
            ConversationMessage(
                content: content,
                isFromUser: true,
                timestamp: createdAt
            )
        ]
        
        // For anonymous users, set expiry to 24 hours from now
        if userId == "anonymous" {
            self.expiresAt = Date().addingTimeInterval(60 * 60 * 24) // 24 hours
        }
    }
    
    // Add a method to add AI response to the conversation
    func addAIResponse(_ response: String) {
        self.aiResponse = response
        
        // Add the AI response to the conversation thread
        let message = ConversationMessage(
            content: response,
            isFromUser: false,
            timestamp: Date()
        )
        self.conversationThread.append(message)
    }
    
    // Add a method to add user reply to the conversation
    func addUserReply(_ reply: String) {
        let message = ConversationMessage(
            content: reply,
            isFromUser: true,
            timestamp: Date()
        )
        self.conversationThread.append(message)
    }
} 