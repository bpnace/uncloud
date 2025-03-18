# Uncloud - AI Self-Esteem Therapy App

Uncloud is a native iOS app that allows users to enter negative or intrusive thoughts and receive short, emotionally intelligent responses from a GPT-powered therapeutic agent. The app provides concise (2–4 sentences), emotionally validating responses designed to offer a quick motivational push.

## Key Features

- **Anonymous by Default**: All data is ephemeral and deleted after 24 hours unless the user signs in
- **Thought Capture**: Enter negative thoughts and receive AI-powered therapeutic responses
- **Multiple AI Providers**: Support for both OpenAI and Hugging Face models
- **WidgetKit Integration**: Display the latest response on your iOS home screen
- **Pro Features** (for logged-in users):
  - Persistent journaling with tags and mood tracking
  - Daily reminders via Push Notifications
  - Custom therapeutic sessions
  - AI tone personalization

## Tech Stack

- Swift 5.9
- SwiftUI (main UI framework)
- SwiftData (for local storage)
- WidgetKit (for iOS home screen widgets)
- Combine (for reactive data binding)
- Firebase Authentication (email/password, anonymous login)
- Firebase Firestore (for cloud sync of user data)
- Stripe iOS SDK (for subscription and payments)
- OpenAI API (for therapeutic responses)
- Hugging Face Inference API (alternative AI provider)

## Project Structure

```
Uncloud/
├── Models/               # SwiftData models
├── Views/                # SwiftUI views
├── ViewModels/           # Business logic
├── Services/             # API services, Firebase, etc.
├── Utilities/            # Helper functions
├── Widgets/              # WidgetKit extensions
├── Assets.xcassets/      # Images and colors
└── Preview Content/      # Preview assets
```

## Getting Started

### Prerequisites

- Xcode 15.0 or higher
- iOS 17.0+ target
- An API key from either OpenAI or Hugging Face
- (Optional) Firebase project with Authentication and Firestore
- (Optional) Stripe account for payments

### Installation

1. Clone the repository
2. Open the project in Xcode
3. Add your OpenAI or Hugging Face API key in the Settings screen
4. Build and run the app in the simulator or on a device

### Configuration

#### AI Providers

The app supports two AI providers:

1. **OpenAI API**:
   - Sign up at [OpenAI](https://openai.com/api/)
   - Create an API key
   - Add the key in the app's Settings screen
   - Supported models: GPT-4o, GPT-4o-mini, GPT-3.5-turbo

2. **Hugging Face API**:
   - Sign up at [Hugging Face](https://huggingface.co/)
   - Create an API token at [Hugging Face Tokens](https://huggingface.co/settings/tokens)
   - Add the token in the app's Settings screen
   - Supported models: Google Gemma 2, Meta Llama 3, Microsoft Phi-4, Qwen 2.5

#### Firebase Setup (Optional)

For user accounts and cloud sync:

1. Create a Firebase project
2. Add an iOS app to your project
3. Download the `GoogleService-Info.plist` and add it to the project
4. Enable Authentication (email/password and anonymous)
5. Set up Firestore with appropriate security rules

#### Widget Setup

For WidgetKit to work properly:

1. Set up an App Group in your Apple Developer account
2. Update the "group.com.yourcompany.uncloud" identifier in the code to match your App Group
3. Enable App Groups in your app's capabilities
4. Enable App Groups in your widget extension's capabilities

## Development Roadmap

- [x] Core app structure
- [x] Basic thought capture
- [x] AI response integration
  - [x] OpenAI API integration
  - [x] Hugging Face API integration
- [x] User authentication
  - [x] Anonymous login
  - [x] Email/password authentication
  - [x] Sign out functionality
- [x] Data persistence
  - [x] Local storage with SwiftData
  - [x] 24-hour expiry for anonymous users
  - [x] Cloud sync for authenticated users
- [x] Widget functionality
  - [x] Display latest thought and response
  - [x] Support for different widget sizes
  - [x] Data sharing between app and widget
- [x] Pro features and payments
  - [x] Subscription service implementation
  - [x] Subscription tier options (monthly/yearly)
  - [x] Pro features paywall
  - [x] Subscription management UI
- [x] Tiered user model
  - [x] Anonymous users (3 responses total)
  - [x] Basic users (8 responses daily)
  - [x] Pro users (18 responses daily)
  - [x] Usage tracking and limits
  - [x] Conditional UI based on tier
- [x] Enhanced UI/UX
  - [x] Improved AI response cleaning and formatting
  - [x] Google-style centered input field
  - [x] Cloud animation for loading states
  - [x] Smooth scrolling transitions
  - [x] Consistent design across onboarding and main views
  - [x] Enhanced settings view with account management options
  - [x] Animated splash screen on app launch
  - [x] Redesigned limit reached view with animations
- [x] Journaling features
  - [x] Journal entry creation and management
  - [x] Mood tracking for entries
  - [x] Tag system for categorization
  - [x] Calendar view for entry history
- [x] Notifications and reminders
  - [x] Daily journaling reminders
  - [x] Custom notification scheduling
  - [x] Notification permission handling
  - [x] Deep linking from notifications
- [ ] Analytics and performance monitoring
  - [ ] Basic usage analytics
  - [ ] Error tracking
  - [ ] Performance metrics

## Next Steps

### Analytics and Performance Monitoring

1. Set up basic usage analytics tracking
2. Implement error tracking and reporting
3. Add performance metrics to monitor app responsiveness
4. Create admin dashboard for analytics visualization

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- OpenAI for the GPT API
- Hugging Face for the Inference API
- Firebase for authentication and storage
- SwiftUI and SwiftData for the UI framework
- Stripe for payment processing 