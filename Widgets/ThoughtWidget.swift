import WidgetKit
import SwiftUI
import SwiftData

// Widget entry representing the data to display
struct ThoughtEntry: TimelineEntry {
    let date: Date
    let thought: ThoughtWidgetData?
}

// Simple data model for widget
struct ThoughtWidgetData: Codable {
    let content: String
    let response: String
    let createdAt: Date
}

// Provider that generates the timeline entries
struct ThoughtWidgetProvider: TimelineProvider {
    // Placeholder data for previews and while loading
    func placeholder(in context: Context) -> ThoughtEntry {
        ThoughtEntry(
            date: Date(),
            thought: ThoughtWidgetData(
                content: "I feel overwhelmed with work and can't keep up.",
                response: "It's natural to feel overwhelmed when facing many responsibilities. Remember that taking small steps and focusing on one task at a time can help manage that feeling. You're capable of handling this, especially if you prioritize and allow yourself moments of rest.",
                createdAt: Date()
            )
        )
    }
    
    // Snapshot for widget gallery
    func getSnapshot(in context: Context, completion: @escaping (ThoughtEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    // Timeline entries - we'll update this every hour or when new thoughts are created
    func getTimeline(in context: Context, completion: @escaping (Timeline<ThoughtEntry>) -> Void) {
        // Get latest thought from user defaults (shared with main app)
        let thought = getLatestThought()
        
        let entry = ThoughtEntry(date: Date(), thought: thought)
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    // Helper to get the latest thought from shared storage
    private func getLatestThought() -> ThoughtWidgetData? {
        let userDefaults = UserDefaults(suiteName: "group.com.yourcompany.uncloud")
        
        guard let thoughtData = userDefaults?.data(forKey: "latestThought"),
              let decodedThought = try? JSONDecoder().decode(ThoughtWidgetData.self, from: thoughtData) else {
            return nil
        }
        
        return decodedThought
    }
}

// Widget view
struct ThoughtWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ThoughtEntry
    
    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
            
            if let thought = entry.thought {
                VStack(alignment: .leading, spacing: 8) {
                    // Header
                    HStack {
                        Image(systemName: "cloud.sun.fill")
                            .foregroundStyle(.blue, .yellow)
                        Text("Uncloud")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(thought.createdAt, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 4)
                    
                    // Content depends on widget size
                    switch family {
                    case .systemSmall:
                        Text(thought.response)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(6)
                    case .systemMedium:
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your thought:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(thought.content)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            
                            Text("Response:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            Text(thought.response)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(4)
                        }
                    default:
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Your thought:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(thought.content)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(3)
                            
                            Text("Response:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            Text(thought.response)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding()
            } else {
                // No thought available
                VStack(spacing: 8) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.title)
                        .foregroundStyle(.blue, .yellow)
                    
                    Text("No thoughts yet")
                        .font(.headline)
                    
                    Text("Open the app to share your first thought")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
    }
}

// Widget configuration
struct ThoughtWidget: Widget {
    private let kind = "ThoughtWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: ThoughtWidgetProvider()
        ) { entry in
            ThoughtWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Thought of the Day")
        .description("See your latest therapeutic response.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Widget preview
#Preview(as: .systemMedium) {
    ThoughtWidget()
} timeline: {
    ThoughtEntry(
        date: Date(),
        thought: ThoughtWidgetData(
            content: "I feel overwhelmed with work and can't keep up.",
            response: "It's natural to feel overwhelmed when facing many responsibilities. Remember that taking small steps and focusing on one task at a time can help manage that feeling. You're capable of handling this, especially if you prioritize and allow yourself moments of rest.",
            createdAt: Date()
        )
    )
} 