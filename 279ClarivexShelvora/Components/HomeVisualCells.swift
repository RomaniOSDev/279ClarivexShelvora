import SwiftUI

struct HomeHeroBanner: View {
    let prompt: String
    let streakDays: Int
    let projectCount: Int
    let frameCount: Int
    var onContinue: (() -> Void)?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("HomeHero")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()

            LinearGradient(
                colors: [
                    Color("AppBackground").opacity(0.08),
                    Color("AppBackground").opacity(0.45),
                    Color("AppBackground").opacity(0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [Color("AppPrimary").opacity(0.18), Color.clear],
                startPoint: .topTrailing,
                endPoint: .center
            )
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    TagChip(text: "\(streakDays)d streak", emphasized: true)
                    TagChip(text: "\(projectCount) projects")
                    TagChip(text: "\(frameCount) beats")
                }

                Text("Build your next story")
                    .font(.title2.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(prompt)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if onContinue != nil {
                    Button {
                        FeedbackService.lightTap()
                        onContinue?()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Open Latest Project")
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color("AppBackground"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(minHeight: 44)
                        .background(DepthStyle.primaryButtonFill)
                        .clipShape(Capsule())
                        .shadow(color: Color("AppPrimary").opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ScalePressButtonStyle())
                }
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: DepthStyle.heroCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DepthStyle.heroCorner, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color("AppPrimary").opacity(0.45), Color("AppAccent").opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .softElevation(radius: 14, y: 8)
    }
}

struct HomeImageFeatureCard: View {
    let imageName: String
    let title: String
    let subtitle: String
    let badge: String?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 148)
                .clipped()

            LinearGradient(
                colors: [
                    Color.clear,
                    Color("AppBackground").opacity(0.55),
                    Color("AppBackground").opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                if let badge {
                    TagChip(text: badge, emphasized: true)
                }
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 148)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color("AppAccent").opacity(0.18), lineWidth: 1)
        )
        .softElevation(radius: 10, y: 6)
    }
}

struct HomeQuickActionCell: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(systemName: systemImage, size: 42)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .cardChrome(elevated: true, corner: 16)
    }
}
