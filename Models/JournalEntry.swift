import Foundation
import SwiftData

@Model
final class JournalEntry {
    // Basic properties
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    
    // Metadata
    var tags: [String]?
    var mood: String?
    var activityLevel: Int? // 1-10 scale
    var sleepQuality: Int? // 1-10 scale
    var isFavorite: Bool
    
    // Relationships
    var userId: String
    var relatedThoughtIds: [UUID]?
    
    // AI feedback (optional for Pro users)
    var aiAnalysis: String?
    var aiSuggestions: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        tags: [String]? = nil,
        mood: String? = nil,
        activityLevel: Int? = nil,
        sleepQuality: Int? = nil,
        isFavorite: Bool = false,
        userId: String,
        relatedThoughtIds: [UUID]? = nil,
        aiAnalysis: String? = nil,
        aiSuggestions: String? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
        self.mood = mood
        self.activityLevel = activityLevel
        self.sleepQuality = sleepQuality
        self.isFavorite = isFavorite
        self.userId = userId
        self.relatedThoughtIds = relatedThoughtIds
        self.aiAnalysis = aiAnalysis
        self.aiSuggestions = aiSuggestions
    }
} 