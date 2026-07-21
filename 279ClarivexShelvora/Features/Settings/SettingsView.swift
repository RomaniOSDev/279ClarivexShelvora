import SwiftUI
import UIKit
import StoreKit

struct SettingsView: View {
    @ObservedObject var store: AppDataStore
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 18) {
                        StatsDashboardCell(items: [
                            ("Projects", "\(store.activeProjects.count)", "folder.fill"),
                            ("Frames", "\(store.itemsAdded)", "film"),
                            ("Minutes", "\(store.totalMinutesUsed)", "clock.fill"),
                            ("Captions", "\(store.captions.count)", "text.quote"),
                            ("Streak", "\(store.streakDays)", "flame.fill"),
                            ("Sessions", "\(store.totalSessionsCompleted)", "bolt.fill")
                        ])

                        SectionHeaderView(title: "About")

                        Button {
                            FeedbackService.lightTap()
                            rateApp()
                        } label: {
                            SettingsActionCell(title: "Rate Us", systemImage: "star.fill")
                        }
                        .buttonStyle(ScalePressButtonStyle())

                        Button {
                            FeedbackService.lightTap()
                            openLink(.privacyPolicy)
                        } label: {
                            SettingsActionCell(title: "Privacy", systemImage: "hand.raised.fill")
                        }
                        .buttonStyle(ScalePressButtonStyle())

                        Button {
                            FeedbackService.lightTap()
                            openLink(.termsOfUse)
                        } label: {
                            SettingsActionCell(title: "Terms", systemImage: "doc.plaintext.fill")
                        }
                        .buttonStyle(ScalePressButtonStyle())

                        SectionHeaderView(title: "Data")

                        Button {
                            FeedbackService.lightTap()
                            showResetAlert = true
                        } label: {
                            SettingsActionCell(title: "Reset All Data", systemImage: "trash.fill", destructive: true)
                        }
                        .buttonStyle(ScalePressButtonStyle())

                        Text(versionText)
                            .font(.footnote)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, TabBarMetrics.clearance)
                }
                .clearScrollBackground()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {
                    FeedbackService.lightTap()
                }
                Button("Reset", role: .destructive) {
                    FeedbackService.warningNotification()
                    store.resetAllData()
                }
            } message: {
                Text("This will permanently delete all local projects, frames, captions, and progress.")
            }
        }
        .transparentScreenChrome()
    }

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Version \(version)"
    }

    private func openLink(_ link: AppLink) {
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
