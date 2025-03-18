import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var notificationManager = NotificationManager()
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("journalReminderEnabled") private var journalReminderEnabled = false
    @AppStorage("journalReminderTime") private var journalReminderTime = Date.now
    @AppStorage("journalReminderID") private var journalReminderID: String?
    
    @State private var isRequestingPermission = false
    @State private var showTimeSelection = false
    @State private var selectedTime = Date.now
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Permission section
                Section {
                    HStack {
                        Text("Notifications")
                        Spacer()
                        if isRequestingPermission {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text(notificationManager.isAuthorized ? "Authorized" : "Not Authorized")
                            .foregroundColor(notificationManager.isAuthorized ? .green : .red)
                    }
                    
                    if !notificationManager.isAuthorized {
                        Button("Request Permission") {
                            requestNotificationPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                } header: {
                    Text("Notification Permissions")
                } footer: {
                    Text("Uncloud needs notification permissions to send you reminders.")
                }
                
                // Journal reminders section (Pro only)
                if authManager.isPro {
                    Section {
                        HStack {
                            Toggle("Daily Journal Reminder", isOn: $journalReminderEnabled)
                                .onChange(of: journalReminderEnabled) { oldValue, newValue in
                                    if newValue {
                                        if notificationManager.isAuthorized {
                                            showTimeSelection = true
                                        } else {
                                            journalReminderEnabled = false
                                            requestNotificationPermission()
                                        }
                                    } else {
                                        cancelJournalReminder()
                                    }
                                }
                        }
                        
                        if journalReminderEnabled {
                            HStack {
                                Text("Time")
                                Spacer()
                                Text(timeString(from: journalReminderTime))
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTime = journalReminderTime
                                showTimeSelection = true
                            }
                        }
                    } header: {
                        Text("Journal Reminders")
                    } footer: {
                        Text("Set up a daily reminder to write in your journal. This helps build a consistent journaling habit.")
                    }
                    
                    // Sample notifications
                    if notificationManager.isAuthorized {
                        Section {
                            Button("Send Test Notification") {
                                Task {
                                    let testTime = Date().addingTimeInterval(10)
                                    if await notificationManager.scheduleOneTimeReminder(
                                        at: testTime,
                                        title: "Test Notification",
                                        body: "This is a test notification from Uncloud."
                                    ) != nil {
                                        alertTitle = "Test Notification Sent"
                                        alertMessage = "You will receive a notification in about 10 seconds."
                                        showAlert = true
                                    }
                                }
                            }
                        } header: {
                            Text("Test")
                        } footer: {
                            Text("Send a test notification to verify everything is working.")
                        }
                    }
                } else {
                    // Pro upgrade banner for non-Pro users
                    Section {
                        ProFeatureBanner(
                            title: "Pro Feature",
                            description: "Upgrade to Pro to set up journal reminders and get daily prompts to help you stay consistent.",
                            iconName: "bell.badge.fill"
                        )
                    }
                }
            }
            .navigationTitle("Notification Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showTimeSelection) {
                TimeSelectionView(
                    selectedTime: $selectedTime, 
                    onSave: { 
                        journalReminderTime = selectedTime
                        scheduleJournalReminder()
                    }
                )
                .presentationDetents([.height(380)])
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                notificationManager.checkAuthorizationStatus()
                notificationManager.registerNotificationCategories()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func requestNotificationPermission() {
        isRequestingPermission = true
        
        Task {
            let granted = await notificationManager.requestAuthorization()
            
            DispatchQueue.main.async {
                isRequestingPermission = false
                
                if granted && journalReminderEnabled {
                    showTimeSelection = true
                } else if !granted {
                    alertTitle = "Permission Denied"
                    alertMessage = "Please enable notifications for Uncloud in the iOS Settings app to receive reminders."
                    showAlert = true
                }
            }
        }
    }
    
    private func scheduleJournalReminder() {
        guard notificationManager.isAuthorized else {
            journalReminderEnabled = false
            return
        }
        
        Task {
            // Cancel existing reminder if there is one
            if let existingID = journalReminderID {
                await notificationManager.cancelNotification(withIdentifier: existingID)
            }
            
            // Schedule a new one
            if let newID = await notificationManager.scheduleJournalReminder(at: journalReminderTime) {
                journalReminderID = newID
                journalReminderEnabled = true
            } else {
                journalReminderEnabled = false
                alertTitle = "Error"
                alertMessage = "Failed to schedule the reminder. Please try again."
                showAlert = true
            }
        }
    }
    
    private func cancelJournalReminder() {
        Task {
            if let id = journalReminderID {
                await notificationManager.cancelNotification(withIdentifier: id)
                journalReminderID = nil
            }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TimeSelectionView: View {
    @Binding var selectedTime: Date
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Select Reminder Time")
                    .font(.headline)
                    .padding(.top)
                
                DatePicker(
                    "Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                
                Text("You'll receive a journal reminder at this time every day.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

struct ProFeatureBanner: View {
    let title: String
    let description: String
    let iconName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                NavigationLink {
                    Text("Subscription View - Coming Soon")
                        .navigationTitle("Upgrade to Pro")
                } label: {
                    Text("Upgrade")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NotificationSettingsView()
        .environmentObject(AuthManager())
} 