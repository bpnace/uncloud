# AI Self-Esteem Therapy App – Native iOS Xcode Project Workflow

We are building a native iOS app using Swift, SwiftUI, and WidgetKit that allows users to enter negative or intrusive thoughts and receive short, emotionally intelligent responses from a GPT-powered therapeutic agent. The responses are concise (2–4 sentences), emotionally validating, and designed to offer a quick motivational push. By default, all data is ephemeral and deleted after 24 hours unless the user signs in. Logged-in users can access saved thoughts, journal features, and a “Pro” mode.

## Tech Stack & Frameworks
- Swift 5.9
- SwiftUI (main UI framework)
- WidgetKit (for iOS home screen widgets)
- Combine (for reactive data binding)
- URLSession for networking (or third-party Alamofire)
- Codable for model serialization
- CoreData (for local caching and offline support)
- Firebase Authentication (email/password, anonymous login)
- Firebase Firestore (for cloud sync of user data)
- Stripe iOS SDK (for subscription and payments)
- OpenAI API (for therapeutic responses)

## App Modules

### 1. Authentication
- Anonymous sign-in (default) and email/password login via Firebase Auth
- Upgrade path to account creation
- Secure token handling and persistence

### 2. Thought Capture
- SwiftUI form with a multiline TextEditor for input
- Character limit and emotional tone suggestions (optional)
- On submit: send input to OpenAI endpoint via URLSession

### 3. AI Response
- Use OpenAI GPT-4 or 3.5 model
- System prompt: “You are a compassionate and concise therapist. When a user shares a negative or intrusive thought, respond with 2–4 sentences that validate their experience and offer a practical emotional reframe. Never repeat yourself.”
- Use environment variable or allow user-supplied API key for advanced use

### 4. Data Handling
- Save thoughts and responses in Firestore for logged-in users
- Anonymous thoughts stored only locally (CoreData) with 24h expiry (Timer/Date-based cleanup on app launch)
- Firebase security rules restrict access to user-specific data

### 5. Pro Mode
- Stripe SDK integration
- Monthly/yearly subscription unlocks:
  - Persistent journaling with tags and mood tracking
  - Daily reminders (via Push Notifications)
  - Custom therapeutic sessions
  - AI tone personalization
- Stripe webhook backend (Node.js optional) updates Firestore user doc: isPro: true

### 6. WidgetKit
- Home screen widget shows:
  - Last AI response
  - Or “Motivation of the Day” (static or AI-generated quote)
- Tapping widget opens app to input screen
- Use App Groups + UserDefaults for shared data access

### 7. Journaling
- List of previous entries for Pro users
- Search/filter by tag or emotional category
- Optional graph view for mood trends

### 8. Reminders & Push Notifications
- Use UNUserNotificationCenter to request and schedule local notifications
- Pro users can receive daily journaling prompts or motivational nudges

### 9. UI Design
- SwiftUI-based
- Fullscreen input view with soft UI
- Animations on submit (e.g., fade-in for AI response)
- Minimalist, emotionally clean theme with one highlight color
- Modal views for login/register, settings, Pro upgrade

### 10. Privacy & Security
- Comply with GDPR
- Clear disclaimer this is not a substitute for therapy
- Privacy toggle for offline-only mode

## OpenAI Network Manager (Swift Example)
```swift
class GPTService {
    func fetchTherapyResponse(for text: String, completion: @escaping (String?) -> Void) {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else { return }
        let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4-1106-preview",
            "messages": [
                ["role": "system", "content": "You are a compassionate and concise therapist. ..."],
                ["role": "user", "content": text]
            ],
            "temperature": 0.7
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                DispatchQueue.main.async {
                    completion(content)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
}
```

## Testing
- Use XCTest for unit and UI tests
- Mock GPT responses with stubs
- Integration test for user flow: input > response > optional save

## Deployment
- Firebase project with Firestore + Auth
- Store OpenAI key securely using Keychain or encrypted config
- Use App Store Connect for distribution
- Stripe account + in-app purchase SKUs for subscription

