import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case home
    case studio
    case insights
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .studio: return "Studio"
        case .insights: return "Insights"
        case .settings: return "Settings"
        }
    }

    var symbolName: String {
        switch self {
        case .home: return "house.fill"
        case .studio: return "square.stack.3d.up.fill"
        case .insights: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    FeedbackService.lightTap()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.symbolName)
                            .font(.system(size: 18, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selection == tab ? Color("AppBackground") : Color("AppTextSecondary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        Group {
                            if selection == tab {
                                DepthStyle.selectedFill
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .shadow(color: Color("AppPrimary").opacity(0.35), radius: 6, x: 0, y: 3)
                            } else {
                                Color.clear
                            }
                        }
                    )
                }
                .buttonStyle(ScalePressButtonStyle())
                .frame(minHeight: 48)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(DepthStyle.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(DepthStyle.sheen)
                        .allowsHitTesting(false)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color("AppAccent").opacity(0.16), lineWidth: 1)
                )
        )
        .softElevation(radius: 12, y: 6)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}

enum TabBarMetrics {
    static let clearance: CGFloat = 100
}
