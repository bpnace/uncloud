import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    
    var body: some View {
        if isActive {
            // Return EmptyView as this is simply a wrapper
            // The actual content is controlled by the parent view
            EmptyView()
        } else {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 10) {
                    // Cloud icon without animation
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.blue, .yellow)
                    
                    // App name
                    Text("Uncloud")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                    
                    // Tagline
                    Text("AI Self-Esteem Therapy")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .onAppear {
                    // After a delay, set isActive to true to trigger the transition
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
} 
