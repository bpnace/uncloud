import SwiftUI
import SwiftData

struct JournalCalendarView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @Query private var journalEntries: [JournalEntry]
    
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var showingNewEntry = false
    
    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    
    var entriesForSelectedDate: [JournalEntry] {
        let userEntries = journalEntries.filter { $0.userId == authManager.currentUserId }
        
        return userEntries.filter { entry in
            calendar.isDate(entry.createdAt, inSameDayAs: selectedDate)
        }.sorted { $0.createdAt > $1.createdAt }
    }
    
    var daysWithEntries: Set<Date> {
        let userEntries = journalEntries.filter { $0.userId == authManager.currentUserId }
        
        let dates = userEntries.map { entry in
            calendar.startOfDay(for: entry.createdAt)
        }
        
        return Set(dates)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(monthYearString(from: currentMonth))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            hasEntry: daysWithEntries.contains(calendar.startOfDay(for: date)),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        // Empty cell for padding at start/end of month
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .padding(.horizontal)
            
            // Entries for selected date
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(dateString(from: selectedDate))
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        showingNewEntry = true
                    }) {
                        Label("New Entry", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                
                if entriesForSelectedDate.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.7))
                        
                        Text("No entries for this date")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button("Create Entry") {
                            showingNewEntry = true
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 4)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(entriesForSelectedDate) { entry in
                                NavigationLink(destination: JournalEntryDetailView(entry: entry)) {
                                    CalendarEntryRow(entry: entry)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding(.vertical)
        .sheet(isPresented: $showingNewEntry) {
            JournalEntryCreationView(preselectedDate: selectedDate)
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Methods
    
    private func daysInMonth() -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let startOfMonth = interval.start
        let startWeekday = calendar.component(.weekday, from: startOfMonth)
        
        // 1-based index to 0-based index
        let firstWeekdayOffset = (startWeekday - calendar.firstWeekday + 7) % 7
        
        // Calculate the dates to display
        var dates: [Date?] = Array(repeating: nil, count: firstWeekdayOffset)
        
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return dates
        }
        
        let numberOfDaysInMonth = calendar.component(.day, from: endOfMonth)
        
        for day in 1...numberOfDaysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                dates.append(date)
            }
        }
        
        // Pad the end to make complete weeks
        let remainingDays = (7 - (dates.count % 7)) % 7
        dates.append(contentsOf: Array(repeating: nil, count: remainingDays))
        
        return dates
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
}

// MARK: - Supporting Views

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let hasEntry: Bool
    let isCurrentMonth: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.blue : Color.clear)
                .aspectRatio(1, contentMode: .fit)
            
            Text("\(calendar.component(.day, from: date))")
                .font(.callout)
                .foregroundColor(textColor)
        }
        .overlay(
            Circle()
                .stroke(hasEntry ? Color.orange : Color.clear, lineWidth: 2)
                .padding(4)
                .opacity(hasEntry ? 1.0 : 0.0)
        )
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isCurrentMonth {
            return .primary
        } else {
            return .secondary.opacity(0.5)
        }
    }
}

struct CalendarEntryRow: View {
    let entry: JournalEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time indicator
            VStack(spacing: 4) {
                Text(formatTime(entry.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let mood = entry.mood {
                    moodIndicator(for: mood)
                        .frame(width: 24, height: 24)
                }
            }
            
            // Entry content
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(entry.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let tags = entry.tags, !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                            
                            if (tags.count > 3) {
                                Text("+\(tags.count - 3)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func moodIndicator(for mood: String) -> some View {
        let color: Color
        let systemName: String
        
        switch mood.lowercased() {
        case "great", "excited":
            color = .green
            systemName = "face.smiling.fill"
        case "good", "grateful", "calm":
            color = .blue
            systemName = "face.smiling"
        case "neutral":
            color = .gray
            systemName = "face.dashed"
        case "sad":
            color = .orange
            systemName = "face.sad"
        case "anxious", "stressed", "tired":
            color = .red
            systemName = "face.concerned"
        default:
            color = .gray
            systemName = "face.dashed"
        }
        
        return Image(systemName: systemName)
            .foregroundColor(color)
    }
}

// Extension to JournalEntryCreationView to support preselected date
extension JournalEntryCreationView {
    init(preselectedDate: Date? = nil) {
        self.init()
        if let date = preselectedDate {
            // Add functionality in the future to use the preselected date
            // This would allow entries to be backdated when created from the calendar
        }
    }
}

#Preview {
    NavigationView {
        JournalCalendarView()
            .environmentObject(AuthManager())
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
} 