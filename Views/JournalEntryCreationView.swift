import SwiftUI
import SwiftData

struct JournalEntryCreationView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Form fields
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedMood: String = "Neutral"
    @State private var sleepQuality: Int = 5
    @State private var activityLevel: Int = 5
    @State private var newTag: String = ""
    @State private var tags: [String] = []
    @State private var isShowingTagInput = false
    
    // UI states
    @State private var isAnalyzing = false
    @State private var aiAnalysis: String = ""
    @State private var aiSuggestions: String = ""
    @FocusState private var fieldInFocus: Field?
    
    // Constants
    private let moodOptions = ["Great", "Good", "Neutral", "Sad", "Anxious", "Stressed", "Tired", "Excited", "Grateful", "Calm"]
    private let characterLimit = 5000
    
    enum Field: Hashable {
        case title, content, tagInput
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Pro badge
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Pro Feature")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Title field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                        
                        TextField("Entry title", text: $title)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .focused($fieldInFocus, equals: .title)
                    }
                    
                    // Content field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Journal Entry")
                                .font(.headline)
                            Spacer()
                            Text("\(content.count)/\(characterLimit)")
                                .font(.caption)
                                .foregroundColor(
                                    content.count > Int(Double(characterLimit) * 0.9) 
                                    ? (content.count > characterLimit ? .red : .orange) 
                                    : .secondary
                                )
                        }
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .padding(4)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .focused($fieldInFocus, equals: .content)
                    }
                    
                    // Mood selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How are you feeling?")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(moodOptions, id: \.self) { mood in
                                    MoodButton(
                                        mood: mood,
                                        isSelected: selectedMood == mood,
                                        action: {
                                            selectedMood = mood
                                        }
                                    )
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
                            Text("\(sleepQuality)/10")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(sleepQuality) },
                            set: { sleepQuality = Int($0) }
                        ), in: 1...10, step: 1)
                        .tint(.blue)
                    }
                    
                    // Activity level
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Activity Level")
                                .font(.headline)
                            Spacer()
                            Text("\(activityLevel)/10")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(activityLevel) },
                            set: { activityLevel = Int($0) }
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
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        fieldInFocus = .tagInput
                                    }
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
                                    .focused($fieldInFocus, equals: .tagInput)
                                
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
                            ForEach(tags, id: \.self) { tag in
                                TagView(tag: tag) {
                                    removeTag(tag)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    // AI Analysis section (Pro users only)
                    if authManager.isPro && !content.isEmpty && content.count > 50 {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider()
                                .padding(.vertical, 4)
                            
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                                Text("AI Insights")
                                    .font(.headline)
                                Spacer()
                                
                                if !isAnalyzing && aiAnalysis.isEmpty {
                                    Button(action: generateAIAnalysis) {
                                        Text("Generate")
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.purple.opacity(0.2))
                                            .foregroundColor(.purple)
                                            .cornerRadius(20)
                                    }
                                }
                                
                                if isAnalyzing {
                                    ProgressView()
                                        .tint(.purple)
                                }
                            }
                            
                            if !aiAnalysis.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Analysis")
                                        .font(.subheadline.bold())
                                    
                                    Text(aiAnalysis)
                                        .padding()
                                        .background(Color.purple.opacity(0.05))
                                        .cornerRadius(8)
                                    
                                    if !aiSuggestions.isEmpty {
                                        Text("Suggestions")
                                            .font(.subheadline.bold())
                                        
                                        Text(aiSuggestions)
                                            .padding()
                                            .background(Color.purple.opacity(0.05))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    
                    // Submit button
                    Button(action: saveJournalEntry) {
                        Text("Save Journal Entry")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid)
                    .padding(.top, 10)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveJournalEntry()
                    }
                    .bold()
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("New Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Actions
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
            isShowingTagInput = false
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func saveJournalEntry() {
        guard isFormValid, let userId = authManager.currentUserId else { return }
        
        let entry = JournalEntry(
            title: title,
            content: content,
            tags: tags.isEmpty ? nil : tags,
            mood: selectedMood,
            activityLevel: activityLevel,
            sleepQuality: sleepQuality,
            userId: userId,
            aiAnalysis: aiAnalysis.isEmpty ? nil : aiAnalysis,
            aiSuggestions: aiSuggestions.isEmpty ? nil : aiSuggestions
        )
        
        modelContext.insert(entry)
        try? modelContext.save()
        
        dismiss()
    }
    
    private func generateAIAnalysis() {
        guard content.count >= 50 else { return }
        
        isAnalyzing = true
        
        // Simulate AI analysis generation (would be replaced with actual API call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            aiAnalysis = "This journal entry reflects a \(selectedMood.lowercased()) mood state. Your writing shows signs of self-reflection and awareness of your emotional state."
            
            aiSuggestions = "Consider practicing mindfulness techniques to help manage your feelings. Regular journaling about your sleep and activity patterns may reveal helpful insights over time."
            
            isAnalyzing = false
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        content.count <= characterLimit
    }
}

// MARK: - Supporting Views

struct MoodButton: View {
    let mood: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(mood)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct TagView: View {
    let tag: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .padding(.leading, 8)
                .padding(.vertical, 6)
            
            Button(action: onDelete) {
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

struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if x + viewSize.width > width {
                // Move to next row
                y += maxHeight + spacing
                x = 0
                maxHeight = 0
            }
            
            maxHeight = max(maxHeight, viewSize.height)
            x += viewSize.width + spacing
        }
        
        height = y + maxHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if x + viewSize.width > bounds.maxX {
                // Move to next row
                y += maxHeight + spacing
                x = bounds.minX
                maxHeight = 0
            }
            
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: viewSize.width, height: viewSize.height))
            maxHeight = max(maxHeight, viewSize.height)
            x += viewSize.width + spacing
        }
    }
}

#Preview {
    JournalEntryCreationView()
        .environmentObject(AuthManager())
} 