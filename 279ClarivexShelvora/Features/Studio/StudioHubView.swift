import SwiftUI

struct StudioHubView: View {
    @ObservedObject var store: AppDataStore
    @State private var segment = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 0) {
                    SurfaceCard(padding: 10) {
                        Picker("Studio", selection: $segment) {
                            Text("Projects").tag(0)
                            Text("Captions").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: segment) { _ in
                            FeedbackService.lightTap()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                    Group {
                        if segment == 0 {
                            ProjectsView(store: store)
                        } else {
                            CaptionsView(store: store)
                        }
                    }
                    .padding(.bottom, TabBarMetrics.clearance - 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .transparentScreenChrome()
    }
}
