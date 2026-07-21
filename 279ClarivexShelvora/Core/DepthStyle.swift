import SwiftUI

/// Lightweight depth tokens. Prefer one soft shadow per card; no blur, no nested badge shadows.
enum DepthStyle {
    static let cardCorner: CGFloat = 18
    static let heroCorner: CGFloat = 24
    static let chipCorner: CGFloat = 14

    static var screenGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppBackground"),
                Color("AppSurface").opacity(0.92),
                Color("AppBackground")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var ambientGlow: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppPrimary").opacity(0.14),
                Color.clear,
                Color("AppAccent").opacity(0.08)
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    static var cardFill: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppSurface").opacity(0.98),
                Color("AppBackground").opacity(0.72)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardFillAccent: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppSurface"),
                Color("AppPrimary").opacity(0.18),
                Color("AppBackground").opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var sheen: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppTextPrimary").opacity(0.10),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .center
        )
    }

    static var primaryButtonFill: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppAccent")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var selectedFill: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppAccent").opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct CardChrome: ViewModifier {
    var accentBorder: Bool = false
    var elevated: Bool = true
    var corner: CGFloat = DepthStyle.cardCorner

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(accentBorder ? DepthStyle.cardFillAccent : DepthStyle.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .fill(DepthStyle.sheen)
                            .allowsHitTesting(false)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .stroke(
                                accentBorder
                                    ? Color("AppPrimary").opacity(0.55)
                                    : Color("AppAccent").opacity(0.14),
                                lineWidth: accentBorder ? 1.5 : 1
                            )
                    )
            )
            .shadow(
                color: elevated ? Color.black.opacity(0.28) : .clear,
                radius: elevated ? 10 : 0,
                x: 0,
                y: elevated ? 6 : 0
            )
    }
}

struct SoftElevation: ViewModifier {
    var radius: CGFloat = 10
    var y: CGFloat = 6

    func body(content: Content) -> some View {
        content.shadow(color: Color.black.opacity(0.28), radius: radius, x: 0, y: y)
    }
}

extension View {
    func cardChrome(accentBorder: Bool = false, elevated: Bool = true, corner: CGFloat = DepthStyle.cardCorner) -> some View {
        modifier(CardChrome(accentBorder: accentBorder, elevated: elevated, corner: corner))
    }

    func softElevation(radius: CGFloat = 10, y: CGFloat = 6) -> some View {
        modifier(SoftElevation(radius: radius, y: y))
    }
}
