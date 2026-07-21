import SwiftUI

struct ContentView: View {
    @ObservedObject private var store = AppDataStore.shared

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView(store: store)
            } else {
                OnboardingView(store: store)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.3), value: store.hasSeenOnboarding)
    }
}

#Preview {
    ContentView()
}
