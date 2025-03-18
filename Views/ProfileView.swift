import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var showingEditProfile = false
    @State private var showingSubscriptionView = false
    
    var currentUser: User? {
        guard let userId = authManager.currentUserId else { return nil }
        return users.first { $0.id == userId }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account Information")) {
                    HStack {
                        Text("Display Name")
                        Spacer()
                        Text(currentUser?.displayName ?? "Anonymous User")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(currentUser?.email ?? "Not signed in")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Account Type")
                        Spacer()
                        HStack {
                            Text(currentUser?.isPro == true ? "Pro" : "Free")
                                .foregroundColor(.secondary)
                            
                            if currentUser?.isPro == true {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    
                    if currentUser?.isPro == true, let expirationDate = currentUser?.proExpirationDate {
                        HStack {
                            Text("Renews On")
                            Spacer()
                            Text(expirationDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button("Edit Profile") {
                        if let user = currentUser {
                            displayName = user.displayName ?? ""
                            email = user.email ?? ""
                        }
                        showingEditProfile = true
                    }
                }
                
                Section(header: Text("Stats")) {
                    HStack {
                        Text("Thoughts Recorded")
                        Spacer()
                        Text("\(currentUser?.thoughtCount ?? 0)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Journal Entries")
                        Spacer()
                        Text("\(currentUser?.journalEntryCount ?? 0)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Account Created")
                        Spacer()
                        Text(currentUser?.createdAt.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
                
                if currentUser?.isPro == false {
                    Section {
                        Button {
                            showingSubscriptionView = true
                        } label: {
                            HStack {
                                Image(systemName: "star.circle")
                                    .foregroundColor(.yellow)
                                Text("Upgrade to Pro")
                                    .bold()
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Sign Out") {
                        authManager.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                VStack(spacing: 20) {
                    Text("Edit Profile")
                        .font(.title2)
                        .bold()
                    
                    TextField("Display Name", text: $displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .disabled(true) // Email changes require verification
                    
                    HStack {
                        Button("Cancel") {
                            showingEditProfile = false
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Save") {
                            updateProfile()
                            showingEditProfile = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding()
            }
            .sheet(isPresented: $showingSubscriptionView) {
                SubscriptionView()
                    .environmentObject(authManager)
                    .environmentObject(subscriptionManager)
            }
        }
        .onAppear {
            if users.isEmpty && authManager.currentUserId != nil {
                // Create placeholder user for demo
                let newUser = User(
                    id: authManager.currentUserId ?? UUID().uuidString,
                    email: "user@example.com",
                    displayName: "Demo User",
                    thoughtCount: 5,
                    journalEntryCount: 2
                )
                modelContext.insert(newUser)
            }
            
            // Check subscription status when profile appears
            if let userId = authManager.currentUserId {
                subscriptionManager.checkSubscriptionStatus(for: userId)
            }
        }
    }
    
    private func updateProfile() {
        if let user = currentUser {
            user.displayName = displayName
            // Email change would require verification in a real app
            try? modelContext.save()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(UsageManager())
        .modelContainer(for: User.self, inMemory: true)
} 