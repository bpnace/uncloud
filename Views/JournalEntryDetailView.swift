import SwiftUI
import SwiftData

struct JournalEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @Bindable var entry: JournalEntry
    @State private var isEditing = false
    
    // Edit mode state
    @State private var editedTitle: String = ""
    @State private var editedContent: String = ""
    @State private var editedMood: String = ""
    @State private var editedSleepQuality: Int = 5
    @State private var editedActivityLevel: Int = 5
    @State private var editedTags: [String] = []
    @State private var newTag: String = ""
    @State private var isShowingTagInput = false
    
    // Mood options
    private let moodOptions = ["Great", "Good", "Neutral", "Sad", "Anxious", "Stressed", "Tired", "Excited", "Grateful", "Calm"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Pro Badge
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Pro Feature")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                if isEditing {
                    editModeView
                } else {
                    readModeView
                }
            }
            .padding()
        }
        .navigationTitle(isEditing ? "Edit Entry" : entry.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        // Save the changes
                        saveChanges()
                    } else {
                        // Enter edit mode
                        prepareForEditing()
                    }
                    
                    isEditing.toggle()
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isEditing = false
                    }
                }
            }
        }
    }
    
    // MARK: - Views
    
    private var readModeView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Date
            HStack {
                Text(formatDate(entry.createdAt))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if entry.isFavorite {
                    Label("Favorite", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            
            // Title
            Text(entry.title)
                .font(.title)
                .fontWeight(.bold)
            
            // Content
            Text(entry.content)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            
            // Metadata
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Mood")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(entry.mood ?? "Not specified")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    if let mood = entry.mood {
                        moodIcon(for: mood)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Health metrics
                HStack(spacing: 20) {
                    // Sleep quality
                    if let sleepQuality = entry.sleepQuality {
                        metricView(
                            title: "Sleep", 
                            value: "\(sleepQuality)/10",
                            icon: "bed.double.fill"
                        )
                    }
                    
                    // Activity level
                    if let activityLevel = entry.activityLevel {
                        metricView(
                            title: "Activity", 
                            value: "\(activityLevel)/10",
                            icon: "figure.walk"
                        )
                    }
                }
                
                // Tags
                if let tags = entry.tags, !tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                // AI Insights (if available)
                if let analysis = entry.aiAnalysis, !analysis.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("AI Insights")
                                .font(.headline)
                        }
                        
                        Text(analysis)
                            .padding()
                            .background(Color.purple.opacity(0.05))
                            .cornerRadius(8)
                        
                        if let suggestions = entry.aiSuggestions, !suggestions.isEmpty {
                            Text("Suggestions")
                                .font(.subheadline.bold())
                                .padding(.top, 4)
                            
                            Text(suggestions)
                                .padding()
                                .background(Color.purple.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            
            // Action buttons
            HStack {
                Button(action: toggleFavorite) {
                    Label(
                        entry.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                        systemImage: entry.isFavorite ? "star.slash" : "star"
                    )
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    // Trigger share sheet
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var editModeView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title field
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.headline)
                
                TextField("Entry title", text: $editedTitle)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }
            
            // Content field
            VStack(alignment: .leading, spacing: 8) {
                Text("Journal Entry")
                    .font(.headline)
                
                TextEditor(text: $editedContent)
                    .frame(minHeight: 200)
                    .padding(4)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }
            
            // Mood selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Mood")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(moodOptions, id: \.self) { mood in
                            Button(action: {
                                editedMood = mood
                            }) {
                                Text(mood)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(editedMood == mood ? Color.blue : Color(.secondarySystemBackground))
                                    .foregroundColor(editedMood == mood ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Sleep quality
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sleep Quality")
                        .font(.headline)
                    Spacer()
                    Text("\(editedSleepQuality)/10")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: Binding(
                    get: { Double(editedSleepQuality) },
                    set: { editedSleepQuality = Int($0) }
                ), in: 1...10, step: 1)
                .tint(.blue)
            }
            
            // Activity level
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Activity Level")
                        .font(.headline)
                    Spacer()
                    Text("\(editedActivityLevel)/10")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: Binding(
                    get: { Double(editedActivityLevel) },
                    set: { editedActivityLevel = Int($0) }
                ), in: 1...10, step: 1)
                .tint(.blue)
            }
            
            // Tags
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tags")
                        .font(.headline)
                    
                    Spacer()
                    
                    if !isShowingTagInput {
                        Button(action: {
                            isShowingTagInput = true
                        }) {
                            Label("Add Tag", systemImage: "plus.circle")
                                .font(.caption)
                        }
                    }
                }
                
                // Tag input field (conditional)
                if isShowingTagInput {
                    HStack {
                        TextField("New tag", text: $newTag)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        
                        Button(action: addTag) {
                            Text("Add")
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                
                // Tags display
                FlowLayout(spacing: 8) {
                    ForEach(editedTags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.caption)
                                .padding(.leading, 8)
                                .padding(.vertical, 6)
                            
                            Button(action: {
                                removeTag(tag)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                            .padding(.trailing, 8)
                        }
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(15)
                    }
                }
                .padding(.top, 4)
            }
            
            // Favorite toggle
            Toggle("Mark as Favorite", isOn: $entry.isFavorite)
                .padding(.top, 8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func metricView(title: String, value: String, icon: String) -> some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func moodIcon(for mood: String) -> some View {
        let iconName: String
        let color: Color
        
        switch mood.lowercased() {
        case "great", "excited":
            iconName = "face.smiling.fill"
            color = .green
        case "good", "grateful", "calm":
            iconName = "face.smiling"
            color = .blue
        case "neutral":
            iconName = "face.dashed"
            color = .gray
        case "sad":
            iconName = "face.sad"
            color = .orange
        case "anxious", "stressed", "tired":
            iconName = "face.concerned"
            color = .red
        default:
            iconName = "face.dashed"
            color = .gray
        }
        
        return Image(systemName: iconName)
            .font(.system(size: 28))
            .foregroundColor(color)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func prepareForEditing() {
        editedTitle = entry.title
        editedContent = entry.content
        editedMood = entry.mood ?? "Neutral"
        editedSleepQuality = entry.sleepQuality ?? 5
        editedActivityLevel = entry.activityLevel ?? 5
        editedTags = entry.tags ?? []
    }
    
    private func saveChanges() {
        entry.title = editedTitle
        entry.content = editedContent
        entry.mood = editedMood
        entry.sleepQuality = editedSleepQuality
        entry.activityLevel = editedActivityLevel
        entry.tags = editedTags.isEmpty ? nil : editedTags
        entry.updatedAt = Date()
        
        try? modelContext.save()
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !editedTags.contains(trimmedTag) {
            editedTags.append(trimmedTag)
            newTag = ""
            isShowingTagInput = false
        }
    }
    
    private func removeTag(_ tag: String) {
        editedTags.removeAll { $0 == tag }
    }
    
    private func toggleFavorite() {
        entry.isFavorite.toggle()
        try? modelContext.save()
    }
}

// Preview provider would go here
#Preview {
    // This requires a mock JournalEntry to work
    JournalEntryDetailView(entry: JournalEntry(
        title: "Sample Entry",
        content: "This is a sample journal entry for preview purposes.",
        tags: ["Sample", "Preview"],
        mood: "Good",
        activityLevel: 7,
        sleepQuality: 8,
        isFavorite: false,
        userId: "previewUser"
    ))
    .environmentObject(AuthManager())
} 