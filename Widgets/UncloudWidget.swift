import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), response: "Take a moment to breathe. Remember that your thoughts are not facts, and this moment will pass.", isDefault: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), response: "Take a moment to breathe. Remember that your thoughts are not facts, and this moment will pass.", isDefault: true)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // In the actual implementation, we would:
        // 1. Access the shared App Group for the most recent response
        // 2. If no response, use a default quote
        
        // For now, use a placeholder
        let latestResponse = UserDefaults(suiteName: "group.com.yourcompany.uncloud")?.string(forKey: "latestResponse")
        
        let entry = SimpleEntry(
            date: Date(),
            response: latestResponse ?? "Take a moment to breathe. Remember that your thoughts are not facts, and this moment will pass.",
            isDefault: latestResponse == nil
        )
        
        // Update again in 1 hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let response: String
    let isDefault: Bool
}

struct UncloudWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .foregroundStyle(.blue, .yellow)
                    .font(.headline)
                
                Text(entry.isDefault ? "Daily Insight" : "Your Latest Response")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text(entry.response)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(widgetFamily == .systemSmall ? 3 : 6)
            
            Spacer()
            
            HStack {
                Spacer()
                Text("Uncloud")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct UncloudWidget: Widget {
    let kind: String = "UncloudWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            UncloudWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Therapy Insights")
        .description("Display your latest therapy response or a daily motivational quote.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    UncloudWidget()
} timeline: {
    SimpleEntry(date: .now, response: "Your thoughts do not define you. They are just passing clouds in the sky of your mind.", isDefault: true)
    SimpleEntry(date: .now, response: "Feeling overwhelmed is your body's way of asking for a moment of pause and reflection.", isDefault: false)
} 