import SwiftUI

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            DepthStyle.screenGradient
            DepthStyle.ambientGlow
                .opacity(0.7)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

struct EmptyStateView: View {
    let symbolName: String
    let title: String
    let subtitle: String?

    init(symbolName: String, title: String, subtitle: String? = nil) {
        self.symbolName = symbolName
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("AppPrimary").opacity(0.28), Color("AppAccent").opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(Circle().stroke(Color("AppPrimary").opacity(0.3), lineWidth: 1))
                    .frame(width: 84, height: 84)
                Image(systemName: symbolName)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(Color("AppAccent"))
                    .symbolRenderingMode(.hierarchical)
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            FeedbackService.lightTap()
            action()
        } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color("AppBackground"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: 44)
                .background(
                    DepthStyle.primaryButtonFill
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color("AppPrimary").opacity(0.32), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScalePressButtonStyle())
    }
}

struct ScalePressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SuccessCheckOverlay: View {
    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color("AppAccent"))
                .transition(.scale.combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isVisible = false
                        }
                    }
                }
        }
    }
}

struct AchievementBannerOverlay: View {
    @ObservedObject var store: AppDataStore
    @State private var currentTitle: String?
    @State private var currentDetail: String?
    @State private var isShowing = false
    @State private var isProcessing = false

    var body: some View {
        VStack {
            if isShowing, let title = currentTitle, let detail = currentDetail {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Achievement Unlocked")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AppAccent"))
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardChrome(accentBorder: true, elevated: true, corner: 16)
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .padding(.top, 8)
        .allowsHitTesting(false)
        .onChange(of: store.pendingAchievementIDs) { _ in
            processQueue()
        }
        .onAppear {
            processQueue()
        }
    }

    private func processQueue() {
        guard !isProcessing else { return }
        guard let next = store.pendingAchievementIDs.first else { return }
        isProcessing = true
        let achievement = AchievementID(rawValue: next)
        currentTitle = achievement?.title ?? "Unlocked"
        currentDetail = achievement?.detail ?? ""
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isShowing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isShowing = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if !store.pendingAchievementIDs.isEmpty {
                    store.pendingAchievementIDs.removeFirst()
                }
                isProcessing = false
                processQueue()
            }
        }
    }
}
