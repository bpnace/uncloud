import SwiftUI

struct LoadingAnimationView: View {
    @State private var animating = false
    
    let dotCount = 5
    let duration: Double = 1.2
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 10, height: 10)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .opacity(animating ? 1.0 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: duration)
                            .repeatForever()
                            .delay(duration * Double(index) / Double(dotCount)),
                        value: animating
                    )
            }
        }
        .padding()
        .onAppear {
            animating = true
        }
        .onDisappear {
            animating = false
        }
    }
}

// Alternative loading animation (cloudy themed)
struct CloudyLoadingView: View {
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 0.3
    @State private var scale: CGFloat = 0.9
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<3) { index in
                Image(systemName: "cloud.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor.opacity(0.7 + Double(index) * 0.1))
                    .offset(y: offsetY)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                        value: offsetY
                    )
            }
        }
        .onAppear {
            offsetY = -10
            opacity = 1.0
            scale = 1.1
        }
    }
}

// Preview
struct LoadingAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            LoadingAnimationView()
            CloudyLoadingView()
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 