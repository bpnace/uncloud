import Foundation
import SwiftData
import Combine

class DataManager {
    // Singleton pattern
    static let shared = DataManager()
    
    // Dependencies
    private let firestoreService = FirestoreService.shared
    
    // Cancellables for async operations
    private var cancellables = Set<AnyCancellable>()
    
    // State variables
    private var isAnonymous = true
    private var userId: String?
    private var modelContext: ModelContext?
    
    private init() {}
    
    // Set the model context
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // Set authentication state
    func setAuthState(isAnonymous: Bool, userId: String?) {
        self.isAnonymous = isAnonymous
        self.userId = userId
        firestoreService.setCurrentUser(userId: userId)
    }
    
    // MARK: - Thought Management
    
    // Save a thought (local + cloud if authenticated)
    func saveThought(_ thought: Thought) {
        guard let context = modelContext else { return }
        
        // Save to SwiftData locally
        context.insert(thought)
        try? context.save()
        
        // If user is authenticated (not anonymous), save to Firestore
        if !isAnonymous {
            firestoreService.saveThought(thought)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
    }
    
    // Fetch thoughts from Firestore and merge with local (for authenticated users)
    func syncThoughts(completion: @escaping () -> Void) {
        guard !isAnonymous, let _ = modelContext else {
            completion()
            return
        }
        
        Task {
            await syncThoughts()
            completion()
        }
    }
    
    private func syncThoughts() async {
        guard !isAnonymous, let userId = userId, let context = modelContext else {
            return
        }
        
        do {
            let serverThoughts = try await withCheckedThrowingContinuation { continuation in
                firestoreService.fetchThoughts()
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }, receiveValue: { thoughts in
                        continuation.resume(returning: thoughts)
                    })
                    .store(in: &cancellables)
            }
            
            for serverThought in serverThoughts {
                // Create a fetch descriptor without a predicate
                var descriptor = FetchDescriptor<Thought>()
                
                // Fetch all thoughts
                let allThoughts = try context.fetch(descriptor)
                
                // Find the matching thought by ID
                let existingThought = allThoughts.first { $0.id == serverThought.id }
                
                if let existingThought = existingThought {
                    // Update existing thought
                    existingThought.content = serverThought.content
                    existingThought.aiResponse = serverThought.aiResponse
                    existingThought.isProcessed = serverThought.isProcessed
                    existingThought.expiresAt = serverThought.expiresAt
                    existingThought.tags = serverThought.tags
                    existingThought.mood = serverThought.mood
                    existingThought.isFavorite = serverThought.isFavorite
                } else {
                    // Create new thought
                    let newThought = Thought(
                        id: serverThought.id,
                        content: serverThought.content,
                        createdAt: serverThought.createdAt,
                        aiResponse: serverThought.aiResponse,
                        isProcessed: serverThought.isProcessed,
                        expiresAt: serverThought.expiresAt,
                        tags: serverThought.tags,
                        mood: serverThought.mood,
                        isFavorite: serverThought.isFavorite,
                        isArchived: false,
                        userId: userId
                    )
                    context.insert(newThought)
                }
                
                try context.save()
            }
        } catch {
            print("Error fetching thoughts from Firestore: \(error)")
        }
    }
    
    // Delete expired thoughts for anonymous users
    func cleanupExpiredThoughts() async {
        guard let context = modelContext else { return }
        
        let now = Date()
        
        // Create a fetch descriptor without a predicate
        var descriptor = FetchDescriptor<Thought>()
        
        do {
            // Fetch all thoughts
            let allThoughts = try context.fetch(descriptor)
            
            // Filter expired thoughts manually
            let expiredThoughts = allThoughts.filter { 
                if let expiresAt = $0.expiresAt {
                    return expiresAt < now
                }
                return false
            }
            
            for thought in expiredThoughts {
                context.delete(thought)
            }
            
            try context.save()
        } catch {
            print("Error cleaning up expired thoughts: \(error)")
        }
    }
    
    // MARK: - Journal Entries
    
    // Save a journal entry (local + cloud if authenticated)
    func saveJournalEntry(_ entry: JournalEntry) {
        guard let context = modelContext, !isAnonymous else { return }
        
        // Save to SwiftData locally
        context.insert(entry)
        try? context.save()
        
        // Save to Firestore
        firestoreService.saveJournalEntry(entry)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    // Fetch journal entries from Firestore and merge with local
    func syncJournalEntries(completion: @escaping () -> Void) {
        guard !isAnonymous, let _ = modelContext else {
            completion()
            return
        }
        
        Task {
            await syncJournalEntries()
            completion()
        }
    }
    
    private func syncJournalEntries() async {
        guard !isAnonymous, let userId = userId, let context = modelContext else {
            return
        }
        
        do {
            let serverEntries = try await withCheckedThrowingContinuation { continuation in
                firestoreService.fetchJournalEntries()
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }, receiveValue: { entries in
                        continuation.resume(returning: entries)
                    })
                    .store(in: &cancellables)
            }
            
            for serverEntry in serverEntries {
                // Create a fetch descriptor without a predicate
                var descriptor = FetchDescriptor<JournalEntry>()
                
                // Fetch all journal entries
                let allEntries = try context.fetch(descriptor)
                
                // Find the matching entry by ID
                let existingEntry = allEntries.first { $0.id == serverEntry.id }
                
                if let existingEntry = existingEntry {
                    // Update existing entry
                    existingEntry.title = serverEntry.title
                    existingEntry.content = serverEntry.content
                    existingEntry.mood = serverEntry.mood
                    existingEntry.tags = serverEntry.tags
                } else {
                    // Create new entry
                    let newEntry = JournalEntry(
                        id: serverEntry.id,
                        title: serverEntry.title,
                        content: serverEntry.content,
                        createdAt: serverEntry.createdAt,
                        updatedAt: serverEntry.updatedAt,
                        tags: serverEntry.tags,
                        mood: serverEntry.mood,
                        userId: userId
                    )
                    context.insert(newEntry)
                }
                
                try context.save()
            }
        } catch {
            print("Error fetching journal entries from Firestore: \(error)")
        }
    }
    
    // Handle user sign out (clear local data for anonymous users)
    func handleSignOut() {
        guard let context = modelContext else { return }
        
        // Clear all thoughts that aren't from the current user
        let thoughtDescriptor = FetchDescriptor<Thought>()
        if let thoughts = try? context.fetch(thoughtDescriptor) {
            for thought in thoughts {
                context.delete(thought)
            }
        }
        
        // Clear all journal entries
        let journalDescriptor = FetchDescriptor<JournalEntry>()
        if let entries = try? context.fetch(journalDescriptor) {
            for entry in entries {
                context.delete(entry)
            }
        }
        
        try? context.save()
    }
} 