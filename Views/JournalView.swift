import SwiftUI
import SwiftData

struct JournalView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @Query private var journalEntries: [JournalEntry]
    
    @State private var showingNewEntry = false
    @State private var showingSubscriptionPrompt = false
    @State private var selectedTag: String?
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .list
    
    enum ViewMode {
        case list
        case calendar
    }
    
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
            VStack(spacing: 0) {
                // Pro feature gate
                if !authManager.isPro {
                    ProSubscriptionBanner(showSubscription: $showingSubscriptionPrompt)
                }
                
                // View mode picker (only for Pro users)
                if authManager.isPro {
                    Picker("View Mode", selection: $viewMode) {
                        Label("List", systemImage: "list.bullet")
                            .tag(ViewMode.list)
                        
                        Label("Calendar", systemImage: "calendar")
                            .tag(ViewMode.calendar)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding([.horizontal, .top])
                }
                
                // Journal content
                if authManager.isPro {
                    // Full journal functionality for Pro users
                    if viewMode == .list {
                        // List view
                        if journalEntries.isEmpty || filteredEntries.isEmpty {
                            EmptyJournalView(showNewEntry: $showingNewEntry)
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
                                        JournalEntryDetailView(entry: entry)
                                    } label: {
                                        JournalEntryRow(entry: entry)
                                    }
                                }
                                .onDelete(perform: deleteEntries)
                            }
                            .listStyle(.insetGrouped)
                            .searchable(text: $searchText, prompt: "Search journals")
                        }
                    } else {
                        // Calendar view
                        JournalCalendarView()
                            .environmentObject(authManager)
                    }
                } else {
                    // Limited preview for non-Pro users (blurred/locked entries)
                    ScrollView {
                        VStack(spacing: 16) {
                            // Show a couple of sample entries for preview
                            ForEach(0..<3, id: \.self) { index in
                                LockedJournalPreview(index: index)
                            }
                            
                            // Unlock banner
                            Button(action: {
                                showingSubscriptionPrompt = true
                            }) {
                                HStack {
                                    Image(systemName: "lock.open.fill")
                                    Text("Unlock Premium Journal")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if authManager.isPro {
                            showingNewEntry = true
                        } else {
                            showingSubscriptionPrompt = true
                        }
                    }) {
                        Label("New Entry", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                JournalEntryCreationView()
            }
            .sheet(isPresented: $showingSubscriptionPrompt) {
                VStack {
                    // This would be replaced with your actual SubscriptionView
                    Text("Subscription View - Coming Soon")
                        .padding()
                }
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

// MARK: - Supporting Views

struct ProSubscriptionBanner: View {
    @Binding var showSubscription: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Premium Feature")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button("Upgrade") {
                    showSubscription = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            Text("The Journal is a Premium feature. Upgrade to track your moods, get AI insights, and build self-awareness over time.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding([.horizontal, .top])
    }
}

struct EmptyJournalView: View {
    @Binding var showNewEntry: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
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
            
            Button(action: {
                showNewEntry = true
            }) {
                Text("Create First Entry")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct LockedJournalPreview: View {
    let index: Int
    
    // Sample data for preview entries
    private let sampleTitles = [
        "Morning Reflection",
        "Weekend Thoughts",
        "Progress Note"
    ]
    
    private let sampleDates = [
        Date(),
        Date().addingTimeInterval(-86400),
        Date().addingTimeInterval(-172800)
    ]
    
    private let sampleMoods = [
        "Great",
        "Good",
        "Neutral"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date and lock icon
            HStack {
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
            }
            
            // Title
            Text(sampleTitles[safe: index] ?? "Journal Entry")
                .font(.headline)
            
            // Blurred content
            Text("This is a premium journal entry. Upgrade to Pro to create and view entries...")
                .lineLimit(2)
                .blur(radius: 3)
                .overlay(
                    Rectangle()
                        .fill(Color(.systemBackground).opacity(0.4))
                )
            
            // Tags and mood preview
            HStack {
                Text(sampleMoods[safe: index] ?? "Mood")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: sampleDates[safe: index] ?? Date())
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
            HStack {
                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                
                Text(entry.title)
                    .font(.headline)
                
                Spacer()
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
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
                
                if let tags = entry.tags, !tags.isEmpty {
                    Text("\(tags.count) tag\(tags.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: entry.createdAt)
    }
}

// Array safe index extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview
#Preview {
    JournalView()
        .environmentObject(AuthManager())
        .modelContainer(for: JournalEntry.self, inMemory: true)
} 