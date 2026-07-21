import SwiftUI

struct OnboardingView: View {
    @ObservedObject var store: AppDataStore
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            headline: "Welcome",
            body: "Organize your media collections with storyboards.",
            symbol: "rectangle.stack.fill",
            imageName: "OnboardingWelcome",
            badge: "Storyboards"
        ),
        OnboardingPage(
            headline: "Add Tags",
            body: "Tag images with personalized labels to organize efficiently.",
            symbol: "tag.fill",
            imageName: "OnboardingTags",
            badge: "Tags"
        ),
        OnboardingPage(
            headline: "Start Now",
            body: "Begin by adding your first tagged photo to a storyboard.",
            symbol: "plus.circle.fill",
            imageName: "OnboardingStart",
            badge: "Ready"
        )
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        OnboardingPageView(page: item, index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: page)

                pageIndicator
                    .padding(.top, 8)
                    .padding(.bottom, 18)

                VStack(spacing: 10) {
                    PrimaryButton(title: page == pages.count - 1 ? "Get Started" : "Next") {
                        if page < pages.count - 1 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                page += 1
                            }
                        } else {
                            store.completeOnboarding()
                        }
                    }

                    if page < pages.count - 1 {
                        SecondaryButton(title: "Skip") {
                            store.completeOnboarding()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(
                        index == page
                            ? DepthStyle.primaryButtonFill
                            : LinearGradient(
                                colors: [Color("AppTextSecondary").opacity(0.35), Color("AppTextSecondary").opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .frame(width: index == page ? 22 : 8, height: 8)
                    .shadow(
                        color: index == page ? Color("AppPrimary").opacity(0.35) : .clear,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                    .animation(.easeInOut(duration: 0.25), value: page)
            }
        }
    }
}

private struct OnboardingPage {
    let headline: String
    let body: String
    let symbol: String
    let imageName: String
    let badge: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let index: Int
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 12)

                OnboardingHeroCard(
                    imageName: page.imageName,
                    symbol: page.symbol,
                    badge: page.badge,
                    appeared: appeared
                )

                SurfaceCard(accentBorder: true) {
                    VStack(spacing: 14) {
                        HStack(spacing: 8) {
                            IconBadge(systemName: page.symbol, size: 40)
                            TagChip(text: "Step \(index + 1) of 3", emphasized: true)
                            Spacer(minLength: 0)
                        }

                        Text(page.headline)
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .minimumScaleFactor(0.8)
                            .lineLimit(2)

                        Text(page.body)
                            .font(.body)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)

                        featureHints(for: index)
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 24)
            }
            .padding(.top, 8)
        }
        .clearScrollBackground()
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                appeared = true
            }
        }
        .onChange(of: index) { _ in
            appeared = false
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }

    @ViewBuilder
    private func featureHints(for index: Int) -> some View {
        let hints: [(String, String)] = {
            switch index {
            case 0:
                return [("film", "Visual beats"), ("arrow.right", "Linked scenes")]
            case 1:
                return [("tag", "Custom labels"), ("chart.bar", "Theme insights")]
            default:
                return [("plus", "Create project"), ("square.and.pencil", "Write captions")]
            }
        }()

        HStack(spacing: 10) {
            ForEach(hints, id: \.0) { hint in
                HStack(spacing: 6) {
                    Image(systemName: hint.0)
                        .font(.caption.weight(.semibold))
                    Text(hint.1)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .foregroundStyle(Color("AppAccent"))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color("AppPrimary").opacity(0.18), Color("AppAccent").opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color("AppPrimary").opacity(0.25), lineWidth: 1)
                        )
                )
            }
        }
    }
}

private struct OnboardingHeroCard: View {
    let imageName: String
    let symbol: String
    let badge: String
    let appeared: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipped()

            LinearGradient(
                colors: [
                    Color.clear,
                    Color("AppBackground").opacity(0.35),
                    Color("AppBackground").opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [Color("AppPrimary").opacity(0.22), Color.clear],
                startPoint: .topTrailing,
                endPoint: .center
            )
            .allowsHitTesting(false)

            HStack(spacing: 10) {
                IconBadge(systemName: symbol, size: 44)
                TagChip(text: badge, emphasized: true)
                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: DepthStyle.heroCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DepthStyle.heroCorner, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color("AppPrimary").opacity(0.5), Color("AppAccent").opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .softElevation(radius: 14, y: 8)
        .padding(.horizontal, 20)
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
    }
}
