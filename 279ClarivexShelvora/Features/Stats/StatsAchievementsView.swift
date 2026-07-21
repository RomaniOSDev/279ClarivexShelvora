import SwiftUI

struct StatsAchievementsView: View {
    @ObservedObject var store: AppDataStore

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 18) {
                        summaryCard

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(AchievementID.allCases, id: \.rawValue) { achievement in
                                achievementBadge(achievement)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, TabBarMetrics.clearance)
                }
                .clearScrollBackground()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .transparentScreenChrome()
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))

            HStack {
                metric(title: "Entries", value: "\(store.itemsAdded)")
                metric(title: "Sessions", value: "\(store.totalSessionsCompleted)")
                metric(title: "Streak", value: "\(store.streakDays)d")
            }

            ProgressView(value: Double(unlockedCount), total: Double(AchievementID.allCases.count))
                .tint(Color("AppAccent"))

            Text("\(unlockedCount) of \(AchievementID.allCases.count) unlocked")
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func metric(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color("AppPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity)
    }

    private func achievementBadge(_ achievement: AchievementID) -> some View {
        let unlocked = store.isAchievementUnlocked(achievement)
        return VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(unlocked ? Color("AppPrimary").opacity(0.25) : Color("AppBackground").opacity(0.6))
                    .frame(width: 56, height: 56)
                Image(systemName: achievement.symbolName)
                    .font(.title2)
                    .foregroundStyle(unlocked ? Color("AppPrimary") : Color("AppTextSecondary"))
            }

            Text(achievement.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text(achievement.detail)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)

            Text(unlocked ? "Unlocked" : "Locked")
                .font(.caption2.weight(.bold))
                .foregroundStyle(unlocked ? Color("AppAccent") : Color("AppTextSecondary"))
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(unlocked ? 1 : 0.72)
    }

    private var unlockedCount: Int {
        AchievementID.allCases.filter { store.isAchievementUnlocked($0) }.count
    }
}
