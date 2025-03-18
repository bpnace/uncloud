import SwiftUI
import Combine

struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Text(isSignUp ? "Create Account" : "Sign In")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // Form fields
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        isLoading = true
                        if isSignUp {
                            createAccount()
                        } else {
                            signIn()
                        }
                    }) {
                        HStack {
                            Text(isSignUp ? "Create Account" : "Sign In")
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    
                    Button(action: {
                        isSignUp.toggle()
                    }) {
                        Text(isSignUp ? "Already have an account? Sign in" : "Don't have an account? Sign up")
                            .foregroundColor(.accentColor)
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    Button(action: {
                        isLoading = true
                        signInAnonymously()
                    }) {
                        HStack {
                            Text("Continue as Guest")
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Privacy note
                Text("By signing in, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onChange(of: authManager.isAuthenticated) { _, newValue in
                if newValue {
                    // If we become authenticated, stop showing loading indicator and dismiss the sheet
                    isLoading = false
                    dismiss()
                }
            }
        }
    }
    
    // Sign in with email and password
    private func signIn() {
        authManager.signIn(email: email, password: password) { success in
            isLoading = false
            if !success {
                alertMessage = "Failed to sign in. Please check your email and password."
                showingAlert = true
            } else {
                dismiss()
            }
        }
    }
    
    // Create a new account
    private func createAccount() {
        authManager.createAccount(email: email, password: password) { success in
            isLoading = false
            if !success {
                alertMessage = "Failed to create account. Please try a different email or password."
                showingAlert = true
            } else {
                dismiss()
            }
        }
    }
    
    // Sign in anonymously
    private func signInAnonymously() {
        // Start anonymous sign-in
        authManager.signInAnonymously()
        
        // Fallback in case authentication takes too long or fails
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isLoading = false
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthManager())
        .environmentObject(UsageManager())
} 