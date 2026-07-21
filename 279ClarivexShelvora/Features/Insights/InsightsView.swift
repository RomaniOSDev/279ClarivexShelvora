import SwiftUI

struct InsightsView: View {
    @ObservedObject var store: AppDataStore
    @State private var segment = 0

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 0) {
                    SurfaceCard(padding: 10) {
                        Picker("Insights", selection: $segment) {
                            Text("Themes").tag(0)
                            Text("Review").tag(1)
                            Text("Badges").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: segment) { _ in FeedbackService.lightTap() }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    ScrollView {
                        Group {
                            switch segment {
                            case 0: themeGraphSection
                            case 1: weeklyReviewSection
                            default: achievementsSection
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, TabBarMetrics.clearance)
                    }
                    .clearScrollBackground()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .transparentScreenChrome()
    }

    private var themeGraphSection: some View {
        let frequencies = store.tagFrequencies()
        let pairs = store.coOccurrences()
        let maxCount = max(frequencies.first?.count ?? 1, 1)

        return VStack(alignment: .leading, spacing: 18) {
            InsightBannerCell(text: store.topMotifInsight())

            SectionHeaderView(title: "Theme Map", subtitle: "Node size follows tag frequency")

            if frequencies.isEmpty {
                EmptyStateCard(
                    symbolName: "circle.grid.cross",
                    title: "No themes yet",
                    subtitle: "Tag frames in your storyboards to build the map."
                )
            } else {
                SurfaceCard(padding: 8) {
                    ThemeMapCanvas(frequencies: Array(frequencies.prefix(12)), maxCount: maxCount)
                        .frame(height: 220)
                }

                SectionHeaderView(title: "Frequencies", trailing: store.selectedInsightTag)
                LazyVStack(spacing: 10) {
                    ForEach(frequencies.prefix(10)) { item in
                        Button {
                            FeedbackService.lightTap()
                            store.selectedInsightTag = store.selectedInsightTag == item.tag ? nil : item.tag
                        } label: {
                            FrequencyCell(
                                item: item,
                                maxCount: maxCount,
                                selected: store.selectedInsightTag == item.tag
                            )
                        }
                        .buttonStyle(ScalePressButtonStyle())
                    }
                }

                if store.selectedInsightTag != nil {
                    Text("Filter armed on Home — open Home to see matching beats.")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }

            SectionHeaderView(title: "Often Together", subtitle: "Co-occurrence across frames")
            if pairs.isEmpty {
                EmptyStateCard(
                    symbolName: "link",
                    title: "No pairs yet",
                    subtitle: "Add multiple tags on the same beat."
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(pairs) { pair in
                        CoOccurrenceCell(pair: pair)
                    }
                }
            }
        }
    }

    private var weeklyReviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Weekly Review", subtitle: "What grew in the last 7 days")
            ForEach(Array(store.weeklyReviewLines().enumerated()), id: \.offset) { index, line in
                ReviewLineCell(text: line, index: index)
            }
            PromptHeroCell(prompt: store.dailyPrompt(), streakDays: store.streakDays)
        }
    }

    private var achievementsSection: some View {
        VStack(spacing: 18) {
            StatsDashboardCell(items: [
                ("Frames", "\(store.itemsAdded)", "film"),
                ("Sessions", "\(store.totalSessionsCompleted)", "bolt.fill"),
                ("Streak", "\(store.streakDays)d", "calendar")
            ])

            SectionHeaderView(
                title: "Badges",
                subtitle: "Decorative milestones from real actions",
                trailing: "\(unlockedCount)/\(AchievementID.allCases.count)"
            )

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AchievementID.allCases, id: \.rawValue) { achievement in
                    AchievementCell(
                        achievement: achievement,
                        unlocked: store.isAchievementUnlocked(achievement)
                    )
                }
            }
        }
    }

    private var unlockedCount: Int {
        AchievementID.allCases.filter { store.isAchievementUnlocked($0) }.count
    }
}

private struct ThemeMapCanvas: View {
    let frequencies: [TagFrequency]
    let maxCount: Int

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Canvas { context, size in
                    let pairs = min(frequencies.count, 6)
                    for i in 0..<pairs {
                        for j in (i + 1)..<pairs {
                            let a1 = Double(i) / Double(max(frequencies.count, 1)) * 2 * Double.pi
                            let a2 = Double(j) / Double(max(frequencies.count, 1)) * 2 * Double.pi
                            let radius = min(size.width, size.height) * 0.32
                            let p1 = CGPoint(
                                x: size.width / 2 + CGFloat(cos(a1)) * radius,
                                y: size.height / 2 + CGFloat(sin(a1)) * radius * 0.85
                            )
                            let p2 = CGPoint(
                                x: size.width / 2 + CGFloat(cos(a2)) * radius,
                                y: size.height / 2 + CGFloat(sin(a2)) * radius * 0.85
                            )
                            var path = Path()
                            path.move(to: p1)
                            path.addLine(to: p2)
                            context.stroke(path, with: .color(Color("AppAccent").opacity(0.18)), lineWidth: 1)
                        }
                    }
                }
                .allowsHitTesting(false)

                ForEach(Array(frequencies.enumerated()), id: \.element.id) { index, item in
                    let size = 36 + CGFloat(item.count) / CGFloat(maxCount) * 42
                    let angle = Double(index) / Double(max(frequencies.count, 1)) * 2 * Double.pi
                    let radius = min(geo.size.width, geo.size.height) * 0.32
                    let x = geo.size.width / 2 + CGFloat(cos(angle)) * radius
                    let y = geo.size.height / 2 + CGFloat(sin(angle)) * radius * 0.85

                    ZStack {
                        Circle()
                            .fill(Color("AppPrimary").opacity(0.22 + Double(item.count) / Double(maxCount) * 0.45))
                            .overlay(Circle().stroke(Color("AppAccent").opacity(0.25), lineWidth: 1))
                            .frame(width: size, height: size)
                        Text(item.tag)
                            .font(.system(size: min(14, size * 0.22), weight: .semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(width: size - 8)
                    }
                    .position(x: x, y: y)
                }
            }
        }
        .padding(8)
    }
}
