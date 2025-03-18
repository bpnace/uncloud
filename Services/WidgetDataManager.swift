import Foundation
import WidgetKit

// ThoughtWidgetData is now directly Codable in its declaration

class WidgetDataManager {
    // Singleton pattern
    static let shared = WidgetDataManager()
    
    // Shared UserDefaults container for app and widget
    private let userDefaults = UserDefaults(suiteName: "group.com.yourcompany.uncloud")
    
    private init() {}
    
    // Save the latest thought to shared storage for the widget
    func saveLatestThought(content: String, response: String, createdAt: Date) {
        let thoughtData = ThoughtWidgetData(
            content: content,
            response: response,
            createdAt: createdAt
        )
        
        do {
            let encodedData = try JSONEncoder().encode(thoughtData)
            userDefaults?.set(encodedData, forKey: "latestThought")
            
            // Refresh widgets
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to save thought for widget: \(error.localizedDescription)")
        }
    }
    
    // Get the latest thought from shared storage
    func getLatestThought() -> ThoughtWidgetData? {
        guard let data = userDefaults?.data(forKey: "latestThought") else {
            return nil
        }
        
        do {
            let thoughtData = try JSONDecoder().decode(ThoughtWidgetData.self, from: data)
            return thoughtData
        } catch {
            print("Failed to get thought for widget: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Clear the widget data (e.g. when signing out)
    func clearWidgetData() {
        userDefaults?.removeObject(forKey: "latestThought")
        
        // Refresh widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
} 