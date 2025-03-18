import SwiftUI
import SwiftData

struct JournalView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @Query private var journalEntries: [JournalEntry]
    
    @State private var showingNewEntry = false
    @State private var selectedTag: String?
    @State private var searchText = ""
    
    var filteredEntries: [JournalEntry] {
        let userEntries = journalEntries.filter { $0.userId == authManager.currentUserId }
        
        var filtered = userEntries
        
        // Apply tag filter if selected
        if let tag = selectedTag, !tag.isEmpty {
            filtered = filtered.filter { $0.tags?.contains(tag) == true }
        }
        
        // Apply search filter if text entered
        if !searchText.isEmpty {
            filtered = filtered.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by date, newest first
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
    
    var availableTags: [String] {
        var tags = Set<String>()
        for entry in journalEntries where entry.userId == authManager.currentUserId {
            if let entryTags = entry.tags {
                for tag in entryTags {
                    tags.insert(tag)
                }
            }
        }
        return Array(tags).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if !authManager.isPro {
                    ProUpsellBanner()
                }
                
                if journalEntries.isEmpty {
                    EmptyJournalView()
                } else {
                    List {
                        if !availableTags.isEmpty {
                            TagFilterSection(
                                availableTags: availableTags,
                                selectedTag: $selectedTag
                            )
                        }
                        
                        ForEach(filteredEntries) { entry in
                            NavigationLink {
                                Text("Journal Entry Detail - Coming Soon")
                            } label: {
                                JournalEntryRow(entry: entry)
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    .searchable(text: $searchText, prompt: "Search journals")
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewEntry = true
                    }) {
                        Label("New Entry", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                Text("New Journal Entry View - Coming Soon")
                    .padding()
            }
        }
        .onAppear {
            // For demo purposes, create a sample entry if none exist
            if journalEntries.isEmpty && authManager.currentUserId != nil {
                let sampleEntry = JournalEntry(
                    title: "My First Journal Entry",
                    content: "Today I started using the journaling feature in Uncloud. I'm looking forward to tracking my progress and seeing how my thoughts evolve over time.",
                    tags: ["Welcome", "First"],
                    mood: "Hopeful",
                    userId: authManager.currentUserId ?? ""
                )
                modelContext.insert(sampleEntry)
                try? modelContext.save()
            }
        }
    }
    
    private func deleteEntries(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredEntries[index])
        }
        try? modelContext.save()
    }
}

// Helper Views
struct ProUpsellBanner: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Pro Feature")
                    .font(.headline)
                Spacer()
                Button("Upgrade") {
                    // Will implement upgrade flow later
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            Text("Get unlimited journal entries, mood tracking, and AI insights with Pro.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
}

struct EmptyJournalView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.7))
            
            Text("Your Journal is Empty")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start documenting your journey with journal entries to track your progress over time.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Button("Create First Entry") {
                // Will be connected to new entry sheet
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct TagFilterSection: View {
    let availableTags: [String]
    @Binding var selectedTag: String?
    
    var body: some View {
        Section(header: Text("Filter by Tag")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    TagButton(tag: nil, selectedTag: $selectedTag)
                    
                    ForEach(availableTags, id: \.self) { tag in
                        TagButton(tag: tag, selectedTag: $selectedTag)
                    }
                }
                .padding(.vertical, 5)
            }
            .listRowInsets(EdgeInsets())
        }
    }
}

struct TagButton: View {
    let tag: String?
    @Binding var selectedTag: String?
    
    var isSelected: Bool {
        (tag == nil && selectedTag == nil) || tag == selectedTag
    }
    
    var body: some View {
        Button(action: {
            selectedTag = tag
        }) {
            Text(tag ?? "All")
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct JournalEntryRow: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.title)
                .font(.headline)
            
            Text(entry.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                if let mood = entry.mood {
                    Text(mood)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                Text(entry.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    JournalView()
        .environmentObject(AuthManager())
        .environmentObject(UsageManager())
        .modelContainer(for: JournalEntry.self, inMemory: true)
} 