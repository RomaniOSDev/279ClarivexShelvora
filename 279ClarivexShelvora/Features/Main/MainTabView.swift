import SwiftUI
import Combine

struct MainTabView: View {
    @ObservedObject var store: AppDataStore
    @State private var selection: AppTab = .home
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .home:
                    HomeView(store: store)
                case .studio:
                    StudioHubView(store: store)
                case .insights:
                    InsightsView(store: store)
                case .settings:
                    SettingsView(store: store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar(selection: $selection)

            AchievementBannerOverlay(store: store)
        }
        .onAppear {
            store.tickActiveTime()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                store.tickActiveTime()
            case .inactive, .background:
                store.pauseActiveTimeTracking()
            @unknown default:
                store.pauseActiveTimeTracking()
            }
        }
        .onReceive(Timer.publish(every: 15, on: .main, in: .common).autoconnect()) { _ in
            guard scenePhase == .active else { return }
            store.tickActiveTime()
        }
    }
}
