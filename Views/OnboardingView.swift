import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var usageManager: UsageManager
    
    @State private var currentPage = 0
    @State private var showSignInSheet = false
    @State private var animating = false
    
    let pageCount = 3
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // If authenticated, show MainView (which contains ThoughtCaptureView as its first tab)
                MainView()
                    .environmentObject(authManager)
                    .environmentObject(themeManager)
                    .environmentObject(subscriptionManager)
                    .environmentObject(usageManager)
                    .transition(.opacity)
            } else {
                // If not authenticated, show the onboarding content
                VStack {
                    // Reduced top spacing to lower the logo position
                    Spacer(minLength: UIScreen.main.bounds.height * 0.05)
                    
                    // App Logo & Name - updated to match ThoughtCaptureView style
                    VStack(spacing: 12) {
                        Image(systemName: "cloud.sun.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue, .yellow)
                            .symbolEffect(.pulse)
                            .scaleEffect(animating ? 1.1 : 1.0)
                            .opacity(animating ? 1.0 : 0.9)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6).repeatForever(autoreverses: true), value: animating)
                        
                        Text("Uncloud")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.accentColor)
                        
                        Text("AI Self-Esteem Therapy")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 60) // Increased bottom padding to lower position
                    
                    // Page Content
                    TabView(selection: $currentPage) {
                        // Page 1
                        VStack(spacing: 24) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 60))
                                .foregroundColor(.accentColor)
                            
                            Text("Share Your Thoughts")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Enter negative or intrusive thoughts and receive supportive, validating responses.")
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .foregroundColor(.secondary)
                        }
                        .padding(30)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .padding(.horizontal, 30)
                        .tag(0)
                        
                        // Page 2
                        VStack(spacing: 24) {
                            Image(systemName: "heart.text.square")
                                .font(.system(size: 60))
                                .foregroundColor(.accentColor)
                            
                            Text("AI-Powered Support")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Our AI therapist offers concise, compassionate responses that validate your experience and provide a positive reframe.")
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .foregroundColor(.secondary)
                        }
                        .padding(30)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .padding(.horizontal, 30)
                        .tag(1)
                        
                        // Page 3
                        VStack(spacing: 24) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 60))
                                .foregroundColor(.accentColor)
                            
                            Text("Your Privacy Matters")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("By default, thoughts expire after 24 hours. Create an account to save your journey and unlock Pro features.")
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .foregroundColor(.secondary)
                        }
                        .padding(30)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .padding(.horizontal, 30)
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Hide the default dots
                    .frame(height: 320)
                    
                    // Custom page indicator dots - smaller and positioned below content
                    HStack(spacing: 8) {
                        ForEach(0..<pageCount, id: \.self) { page in
                            Circle()
                                .fill(currentPage == page ? Color.accentColor : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6) // Smaller dots
                        }
                    }
                    .padding(.top, 20) // Space below the TabView
                    
                    Spacer()
                    
                    // Action Buttons - updated to match ThoughtCaptureView button style
                    VStack(spacing: 16) {
                        Button(action: {
                            // Show sign in view with animation
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showSignInSheet = true
                            }
                        }) {
                            Text("Get Started")
                                .font(.headline)
                                .frame(height: 54)
                                .frame(maxWidth: .infinity)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
                    .frame(maxWidth: 600) // Limit max width for larger screens
                }
                .background(Color(.systemBackground))
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    // Start cloud animation
                    animating = true
                }
                .onDisappear {
                    // Stop animation when view disappears
                    animating = false
                }
            }
        }
        .animation(.default, value: authManager.isAuthenticated)
        .sheet(isPresented: $showSignInSheet) {
            SignInView()
                .environmentObject(authManager)
                .environmentObject(subscriptionManager)
                .environmentObject(usageManager)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(UsageManager())
} 