import SwiftUI
import SwiftData

struct ThoughtCaptureView: View {
    @StateObject private var viewModel = ThoughtViewModel()
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var usageManager: UsageManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var showCharacterLimitWarning = false
    @State private var showSignInSheet = false
    @State private var userReply: String = ""
    @State private var showReplyField: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    @FocusState private var isReplyFieldFocused: Bool
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    @State private var showLimitOverlay = true  // Control visibility of limit overlay
    
    // Create a scroll view reader to track scroll position
    @Namespace private var scrollNamespace
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                GeometryReader { geometry in
                    Color.clear.preference(key: ViewHeightKey.self, value: geometry.size.height)
                }
                
                VStack {
                    // ID for scrolling to top
                    HStack { }.id(scrollNamespace)
                    
                    // Make the content centered vertically when no response
                    if viewModel.response.isEmpty {
                        // Add more space at the top (increased spacing)
                        Spacer(minLength: UIScreen.main.bounds.height * 0.09)
                        
                        // App Logo (moved up as requested)
                        Text("Uncloud")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.accentColor)
                            .padding(.bottom, 80) // Increased bottom padding
                            #if DEBUG
                            // Use a simpler and more direct developer reset option
                            .onTapGesture(count: 3) {
                                // Direct reset without alerts or transitions
                                usageManager.devReset()
                                
                                // Show a temporary visual feedback
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                            }
                            #endif
                        
                        // More vertical spacing (requested to move input down more)
                        Spacer(minLength: 40)
                        
                        // Compact Input Field - now more centered on screen like Google
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What's on your mind?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.leading, 5)
                            
                            ZStack(alignment: .trailing) {
                                TextField(viewModel.currentPlaceholder, text: $viewModel.inputText, axis: .vertical)
                                    .lineLimit(3)
                                    .padding(12)
                                    .padding(.trailing, 45)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(20)
                                    .padding(.horizontal, 4)
                                    .focused($isTextFieldFocused)
                                
                                // Character counter
                                Text("\(viewModel.inputText.count)/\(viewModel.characterLimit)")
                                    .font(.caption)
                                    .foregroundColor(
                                        viewModel.inputText.count > viewModel.characterLimit * 4 / 5
                                        ? (viewModel.inputText.count > viewModel.characterLimit ? .red : .orange)
                                        : .secondary
                                    )
                                    .padding(.trailing, 12)
                            }
                            
                            // Submit button that animates out when pressed
                            if !viewModel.isProcessing {
                                Button(action: {
                                    isTextFieldFocused = false
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.processThought()
                                    }
                                }) {
                                    HStack {
                                        Text("Uncloud My Thoughts")
                                        Image(systemName: "arrow.right.circle.fill")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        viewModel.canSubmit ? Color.accentColor : Color.gray.opacity(0.3)
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                }
                                .disabled(!viewModel.canSubmit)
                                .padding(.top, 8)
                                .transition(.opacity)
                            } else {
                                // Loading animation appears in exactly the same place as the button
                                ThoughtButtonLoadingView()
                                    .padding(.top, 8)
                                    .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(maxWidth: 600) // Limit max width for larger screens
                        
                        // Usage counter - moved below input for cleaner look
                        HStack {
                            Spacer()
                            
                            // Show different counters based on tier
                            if usageManager.currentTier.isPeriodic {
                                // Daily counter for Basic and Premium
                                Text("\(usageManager.responsesRemaining) of \(usageManager.currentTier.responseLimit) responses remaining today")
                                    .font(.caption)
                                    .foregroundColor(usageManager.responsesRemaining < 3 ? .orange : .secondary)
                                    .padding(.horizontal)
                            } else {
                                // Total counter for Anonymous
                                Text("\(usageManager.responsesRemaining) of \(usageManager.currentTier.responseLimit) free responses remaining")
                                    .font(.caption)
                                    .foregroundColor(usageManager.responsesRemaining < 2 ? .orange : .secondary)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                    } else {
                        // For when responses are showing
                        VStack(spacing: 24) {
                            // Reduced top spacing when showing response
                            Spacer().frame(height: 20)
                            
                            Text("Uncloud")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.accentColor)
                                .padding(.bottom, 10)
                                .onTapGesture(count: 3) {
                                    // Direct reset without alerts or transitions
                                    usageManager.devReset()
                                    
                                    // Show a temporary visual feedback
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                }
                            
                            // Usage counter
                            HStack {
                                Spacer()
                                
                                // Show different counters based on tier
                                if usageManager.currentTier.isPeriodic {
                                    // Daily counter for Basic and Premium
                                    Text("\(usageManager.responsesRemaining) of \(usageManager.currentTier.responseLimit) responses remaining today")
                                        .font(.caption)
                                        .foregroundColor(usageManager.responsesRemaining < 3 ? .orange : .secondary)
                                        .padding(.horizontal)
                                } else {
                                    // Total counter for Anonymous
                                    Text("\(usageManager.responsesRemaining) of \(usageManager.currentTier.responseLimit) free responses remaining")
                                        .font(.caption)
                                        .foregroundColor(usageManager.responsesRemaining < 2 ? .orange : .secondary)
                                        .padding(.horizontal)
                                }
                            }
                            
                            // Loading animation when processing (visible when waiting for response)
                            if viewModel.isProcessing && !viewModel.conversationMessages.isEmpty {
                                VStack(spacing: 20) {
                                    Text("Unclouding your thoughts...")
                                        .font(.system(.headline, design: .rounded))
                                        .foregroundColor(.secondary)
                                    
                                    CloudyLoadingView()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                                .padding(.horizontal)
                                .transition(.opacity)
                                .animation(.easeInOut, value: viewModel.isProcessing)
                            }
                            
                            Spacer().frame(height: 20)
                            
                            // Conversation Thread Display
                            if !viewModel.conversationMessages.isEmpty && !viewModel.isProcessing {
                                VStack(spacing: 20) {
                                    ForEach(viewModel.conversationMessages.indices, id: \.self) { index in
                                        let message = viewModel.conversationMessages[index]
                                        
                                        ConversationBubble(
                                            message: message,
                                            isLatest: index == viewModel.conversationMessages.count - 1
                                        )
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                    }
                                    
                                    // Reply field (only shown for authenticated users or within anonymous limits)
                                    if showReplyField && !viewModel.limitReached && canReply() {
                                        VStack(alignment: .leading) {
                                            ZStack(alignment: .trailing) {
                                                TextField("Reply to continue the conversation...", text: $userReply, axis: .vertical)
                                                    .lineLimit(3)
                                                    .padding(12)
                                                    .padding(.trailing, 45)
                                                    .background(Color(.secondarySystemBackground))
                                                    .cornerRadius(20)
                                                    .focused($isReplyFieldFocused)
                                                
                                                // Add character counter to reply field
                                                Text("\(userReply.count)/100")
                                                    .font(.caption)
                                                    .foregroundColor(
                                                        userReply.count > 80 
                                                        ? (userReply.count > 100 ? .red : .orange)
                                                        : .secondary
                                                    )
                                                    .padding(.trailing, 12)
                                            }
                                            
                                            Button(action: {
                                                isReplyFieldFocused = false
                                                if !userReply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && userReply.count <= 100 {
                                                    viewModel.processReply(reply: userReply)
                                                    userReply = ""
                                                    showReplyField = false
                                                }
                                            }) {
                                                Text("Send Reply")
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 10)
                                                    .background(
                                                        userReply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || userReply.count > 100
                                                        ? Color.gray.opacity(0.3) 
                                                        : Color.accentColor
                                                    )
                                                    .foregroundColor(.white)
                                                    .cornerRadius(20)
                                                    .font(.subheadline)
                                            }
                                            .disabled(userReply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || userReply.count > 100)
                                        }
                                        .padding(.top, 10)
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                    } else if !viewModel.conversationMessages.isEmpty && !showReplyField && canReply() {
                                        // Reply button - smaller size
                                        Button(action: {
                                            withAnimation {
                                                showReplyField = true
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    isReplyFieldFocused = true
                                                }
                                            }
                                        }) {
                                            Label("Continue Conversation", systemImage: "bubble.right")
                                                .font(.system(.subheadline, design: .rounded))
                                                .fontWeight(.medium)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 15)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(Color.accentColor.opacity(0.1))
                                                )
                                                .foregroundColor(.accentColor)
                                        }
                                        .padding(.top, 8)
                                        .padding(.horizontal, 20)
                                    }
                                    
                                    Divider()
                                        .padding(.vertical, 8)
                                    
                                    // Start New Thought button - smaller size
                                    Button(action: {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                            viewModel.resetView()
                                            showReplyField = false
                                            
                                            // Scroll to top with animation
                                            scrollProxy.scrollTo(scrollNamespace, anchor: .top)
                                        }
                                    }) {
                                        Label("Start New Thought", systemImage: "arrow.clockwise")
                                            .font(.system(.subheadline, design: .rounded))
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 15)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(Color.accentColor.opacity(0.1))
                                            )
                                            .foregroundColor(.accentColor)
                                    }
                                    .padding(.top, 8)
                                    .padding(.horizontal, 20)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
                                )
                                .padding(.horizontal)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .animation(.spring(response: 0.6), value: viewModel.response)
                            }
                            
                            // Show upgrade promotion for anonymous users
                            if authManager.isAnonymous && !viewModel.response.isEmpty {
                                VStack(spacing: 10) {
                                    Text("Create an account to save your conversations")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                    
                                    Button(action: {
                                        showSignInSheet = true
                                    }) {
                                        HStack {
                                            Image(systemName: "person.crop.circle.badge.plus")
                                                .font(.system(size: 18))
                                            Text("Sign In or Create Account")
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue, Color.purple.opacity(0.8)]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                        .shadow(color: Color.purple.opacity(0.4), radius: 5, x: 0, y: 2)
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(.secondarySystemBackground))
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                )
                                .padding()
                                .padding(.bottom, 10)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(.vertical)
                .onPreferenceChange(ViewHeightKey.self) { height in
                    scrollViewHeight = height
                }
            }
            .contentShape(Rectangle())  // Make the entire view tappable
            .onTapGesture {
                // Dismiss keyboard when tapping outside text fields
                isTextFieldFocused = false
                isReplyFieldFocused = false
            }
            .alert(isPresented: $viewModel.showError, content: {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.error ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            })
            .overlay(
                Group {
                    // Show limit overlay when user has reached their limit
                    if (viewModel.limitReached || usageManager.limitReached) && showLimitOverlay {
                        LimitReachedView(
                            onLoginTapped: {
                                if authManager.isAnonymous {
                                    showSignInSheet = true
                                } else if !authManager.isPro {
                                    // Show subscription view when implemented
                                }
                                showLimitOverlay = false // Hide overlay after action
                            },
                            onDismissTapped: {
                                showLimitOverlay = false // Hide overlay when dismissed
                            }
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .zIndex(10) // Ensure overlay appears above other content
                    }
                }
            )
            .sheet(isPresented: $showSignInSheet) {
                SignInView()
                    .environmentObject(authManager)
            }
            .onAppear {
                // Pass model context to view model
                viewModel.modelContext = modelContext
                
                // Set authentication status
                viewModel.setAuthentication(
                    isAuthenticated: authManager.isAuthenticated,
                    userId: authManager.currentUserId ?? "anonymous",
                    isAnonymous: authManager.isAnonymous
                )
                
                // Pass usage manager
                viewModel.usageManager = usageManager
                
                // Reinitialize to load API key
                viewModel.loadAPIKeyFromSettings()
                
                // Reset limit overlay visibility
                if viewModel.limitReached || usageManager.limitReached {
                    showLimitOverlay = true
                }
            }
            .onChange(of: viewModel.limitReached) { _, newValue in
                if newValue {
                    showLimitOverlay = true
                }
            }
            .onChange(of: usageManager.limitReached) { _, newValue in
                if newValue {
                    showLimitOverlay = true
                }
            }
            .onChange(of: viewModel.isProcessing) { _, newValue in
                // When processing completes, check if we should show reply options
                if !newValue && !viewModel.response.isEmpty && !viewModel.conversationMessages.isEmpty {
                    // Don't automatically show reply field on mobile - wait for user to tap button
                    showReplyField = false
                }
            }
        }
    }
    
    // Helper to determine if user can reply based on their tier
    private func canReply() -> Bool {
        if authManager.isPro {
            // Pro users have the most generous limits
            return true
        } else if authManager.isAuthenticated && !authManager.isAnonymous {
            // Basic authenticated users
            return usageManager.responsesRemaining > 0
        } else {
            // Anonymous users with limited responses
            return usageManager.responsesRemaining > 0
        }
    }
}

// Custom loading animation that will replace the button
struct ThoughtButtonLoadingView: View {
    @State private var isAnimating = false
    @State private var offsetY: CGFloat = 0
    @State private var scale: CGFloat = 0.9
    
    var body: some View {
        HStack(spacing: 20) {
            Spacer()
            
            // Cloud animation
            ForEach(0..<3) { index in
                Image(systemName: "cloud.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8 + Double(index) * 0.05))
                    .offset(y: offsetY)
                    .scaleEffect(scale)
                    .animation(
                        Animation.easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.25),
                        value: offsetY
                    )
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.accentColor)
        .foregroundColor(.white)
        .cornerRadius(20)
        .onAppear {
            // Trigger the animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isAnimating = true
                offsetY = -8  // Move clouds up
                scale = 1.1   // Make clouds slightly larger
            }
        }
    }
}

// Conversation Bubble Component
struct ConversationBubble: View {
    let message: ConversationMessage
    let isLatest: Bool
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.isFromUser ? "You" : "Therapist")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                
                if message.isFromUser {
                    // User message with light accent color background
                    userMessageView
                } else {
                    // AI message with blue gradient background
                    aiMessageView
                }
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.85, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser {
                Spacer()
            }
        }
        .id(message.id)
    }
    
    // User message styling
    private var userMessageView: some View {
        Text(message.content)
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .background(Color.accentColor.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(18)
    }
    
    // AI message styling with gradient
    private var aiMessageView: some View {
        Text(message.content)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.7),
                        Color.blue.opacity(0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(18)
    }
}

// At the bottom of the file, add the ViewHeightKey struct
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ThoughtCaptureView()
        .environmentObject(AuthManager())
        .environmentObject(UsageManager())
        .modelContainer(for: Thought.self, inMemory: true)
} 
