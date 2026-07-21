import SwiftUI

// MARK: - Base surfaces

struct SurfaceCard<Content: View>: View {
    var padding: CGFloat = 16
    var accentBorder: Bool = false
    var elevated: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardChrome(accentBorder: accentBorder, elevated: elevated)
    }
}

struct SectionHeaderView: View {
    let title: String
    var subtitle: String? = nil
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppAccent"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}

struct IconBadge: View {
    let systemName: String
    var size: CGFloat = 44
    var tint: Color = Color("AppPrimary")

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DepthStyle.chipCorner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.42), Color("AppBackground").opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DepthStyle.chipCorner, style: .continuous)
                        .stroke(tint.opacity(0.35), lineWidth: 1)
                )
                .frame(width: size, height: size)
            Image(systemName: systemName)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(tint)
        }
    }
}

struct EmojiBadge: View {
    let emoji: String
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color("AppPrimary").opacity(0.34), Color("AppAccent").opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(0.28), lineWidth: 1)
                )
                .frame(width: size, height: size)
            Text(emoji)
                .font(.system(size: size * 0.42))
        }
    }
}

struct TagChip: View {
    let text: String
    var emphasized: Bool = false

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(emphasized ? Color("AppBackground") : Color("AppAccent"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        emphasized
                            ? DepthStyle.primaryButtonFill
                            : LinearGradient(
                                colors: [Color("AppPrimary").opacity(0.22), Color("AppAccent").opacity(0.12)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
            )
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            FeedbackService.lightTap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color("AppPrimary"))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color("AppPrimary").opacity(0.22), Color("AppAccent").opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color("AppPrimary").opacity(0.4), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(ScalePressButtonStyle())
    }
}

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(Color("AppAccent"))
            }
            TextField(placeholder, text: $text)
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 48)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color("AppBackground").opacity(0.55), Color("AppSurface").opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color("AppAccent").opacity(0.16), lineWidth: 1)
                )
        )
    }
}

// MARK: - Feature cells

struct PromptHeroCell: View {
    let prompt: String
    let streakDays: Int

    var body: some View {
        SurfaceCard(accentBorder: true) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    IconBadge(systemName: "lightbulb.fill", size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Prompt of the Day")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AppAccent"))
                        Text("Daily writing spark")
                            .font(.caption2)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                    Spacer()
                    TagChip(text: "\(streakDays)d streak", emphasized: true)
                }
                Text(prompt)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ContinueProjectCell: View {
    let name: String
    let beatCount: Int
    let tags: [String]

    var body: some View {
        SurfaceCard(padding: 0) {
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [Color("AppPrimary"), Color("AppAccent")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: 6)

                HStack(spacing: 14) {
                    IconBadge(systemName: "play.fill", size: 48)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Story Resume")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AppAccent"))
                        Text(name)
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("\(beatCount) beats ready")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                        if !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(tags.prefix(3), id: \.self) { tag in
                                        TagChip(text: tag)
                                    }
                                }
                            }
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color("AppPrimary"))
                }
                .padding(16)
            }
        }
    }
}

struct SmartStackCell: View {
    let kind: SmartStackKind
    let count: Int
    let selected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                IconBadge(systemName: kind.symbolName, size: 36, tint: selected ? Color("AppBackground") : Color("AppPrimary"))
                Spacer()
                Text("\(count)")
                    .font(.title2.bold())
                    .foregroundStyle(selected ? Color("AppBackground") : Color("AppAccent"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(kind.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(selected ? Color("AppBackground") : Color("AppTextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(kind.subtitle)
                .font(.caption2)
                .foregroundStyle(selected ? Color("AppBackground").opacity(0.8) : Color("AppTextSecondary"))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DepthStyle.cardCorner, style: .continuous)
                .fill(selected ? DepthStyle.selectedFill : DepthStyle.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: DepthStyle.cardCorner, style: .continuous)
                        .fill(DepthStyle.sheen)
                        .opacity(selected ? 0 : 1)
                        .allowsHitTesting(false)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DepthStyle.cardCorner, style: .continuous)
                        .stroke(Color("AppAccent").opacity(selected ? 0.0 : 0.14), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(selected ? 0.34 : 0.22), radius: selected ? 12 : 8, x: 0, y: selected ? 7 : 5)
    }
}

struct BeatResultCell: View {
    let frame: StoryFrame
    let projectName: String?

    var body: some View {
        SurfaceCard(padding: 14) {
            HStack(spacing: 14) {
                EmojiBadge(emoji: frame.icon, size: 56)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(frame.title)
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                        Text("\(frame.durationSeconds)s")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AppPrimary"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("AppPrimary").opacity(0.15))
                            .clipShape(Capsule())
                    }
                    if let projectName {
                        Text(projectName)
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineLimit(1)
                    }
                    HStack(spacing: 6) {
                        statusDot(frame.isUntagged ? "Untagged" : "Tagged", alert: frame.isUntagged)
                        statusDot(frame.needsCaption ? "No caption" : "Captioned", alert: frame.needsCaption)
                    }
                    if !frame.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(frame.tags.prefix(4), id: \.self) { tag in
                                    TagChip(text: tag)
                                }
                            }
                        }
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
    }

    private func statusDot(_ text: String, alert: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(alert ? Color("AppAccent") : Color("AppPrimary"))
                .frame(width: 6, height: 6)
            Text(text)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
        }
    }
}

struct ProjectWorkspaceCell: View {
    let project: StoryProject
    let beatCount: Int

    var body: some View {
        SurfaceCard(padding: 14, accentBorder: project.isPinned) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    IconBadge(systemName: project.isArchived ? "archivebox.fill" : "folder.fill", size: 48)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text(project.name)
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            if project.isPinned {
                                Image(systemName: "pin.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppPrimary"))
                            }
                        }
                        Text(project.notes.isEmpty ? "No notes yet" : project.notes)
                            .font(.subheadline)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                HStack(spacing: 8) {
                    metricPill(icon: "film", text: "\(beatCount) beats")
                    metricPill(icon: "clock", text: project.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    Spacer()
                }

                if !project.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(project.tags.prefix(5), id: \.self) { tag in
                                TagChip(text: tag)
                            }
                        }
                    }
                }
            }
        }
    }

    private func metricPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(Color("AppTextSecondary"))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color("AppBackground").opacity(0.55), Color("AppSurface").opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
    }
}

struct CaptionStudioCell: View {
    let item: CaptionItem
    let dateText: String

    var body: some View {
        SurfaceCard(padding: 14) {
            HStack(alignment: .top, spacing: 14) {
                IconBadge(systemName: item.symbolName, size: 54)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        if let beat = item.beatRole {
                            TagChip(text: beat.title, emphasized: true)
                        }
                        if let tone = item.tone {
                            TagChip(text: tone.title)
                        }
                        Spacer()
                    }
                    Text(item.text)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                    HStack {
                        Text(dateText)
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                        if !item.editHistory.isEmpty {
                            Text("·")
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text("\(item.editHistory.count) edits")
                                .font(.caption)
                                .foregroundStyle(Color("AppAccent"))
                        }
                        if !item.variants.isEmpty {
                            Text("·")
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text("\(item.variants.count) variants")
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }
                }
            }
        }
    }
}

struct StoryboardBeatCell: View {
    let frame: StoryFrame
    let index: Int
    let nextTitle: String?

    var body: some View {
        SurfaceCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("BEAT \(index + 1)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color("AppBackground"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("AppPrimary"))
                        .clipShape(Capsule())
                    Spacer()
                    Text("\(frame.durationSeconds)s")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                }
                HStack(spacing: 12) {
                    EmojiBadge(emoji: frame.icon, size: 48)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(frame.title)
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        if !frame.tags.isEmpty {
                            Text(frame.tags.joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                                .lineLimit(1)
                        }
                    }
                }
                if let nextTitle {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right")
                            .font(.caption2.weight(.bold))
                        Text("Next → \(nextTitle)")
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(Color("AppAccent"))
                    .padding(.top, 2)
                }
            }
        }
    }
}

struct FrequencyCell: View {
    let item: TagFrequency
    let maxCount: Int
    let selected: Bool

    var body: some View {
        SurfaceCard(padding: 12, accentBorder: selected) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(item.tag)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    Text("\(item.count)×")
                        .font(.headline)
                        .foregroundStyle(Color("AppAccent"))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color("AppBackground").opacity(0.55))
                        Capsule()
                            .fill(DepthStyle.primaryButtonFill)
                            .frame(width: max(12, geo.size.width * CGFloat(item.count) / CGFloat(max(maxCount, 1))))
                    }
                }
                .frame(height: 8)
                Text(selected ? "Filtering Home" : "Tap to filter")
                    .font(.caption2)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
    }
}

struct CoOccurrenceCell: View {
    let pair: TagCoOccurrence

    var body: some View {
        SurfaceCard(padding: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        TagChip(text: pair.left)
                        Image(systemName: "plus")
                            .font(.caption2)
                            .foregroundStyle(Color("AppTextSecondary"))
                        TagChip(text: pair.right)
                    }
                    Text("Appear together often")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                Spacer()
                Text("\(pair.count)×")
                    .font(.title3.bold())
                    .foregroundStyle(Color("AppPrimary"))
            }
        }
    }
}

struct ReviewLineCell: View {
    let text: String
    let index: Int

    var body: some View {
        SurfaceCard(padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color("AppPrimary").opacity(0.2))
                        .frame(width: 28, height: 28)
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppPrimary"))
                }
                Text(text)
                    .font(.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct AchievementCell: View {
    let achievement: AchievementID
    let unlocked: Bool

    var body: some View {
        SurfaceCard(padding: 14, accentBorder: unlocked) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(unlocked ? Color("AppPrimary").opacity(0.28) : Color("AppBackground").opacity(0.55))
                        .frame(width: 58, height: 58)
                    Image(systemName: achievement.symbolName)
                        .font(.title2)
                        .foregroundStyle(unlocked ? Color("AppPrimary") : Color("AppTextSecondary"))
                }
                Text(achievement.title)
                    .font(.subheadline.weight(.bold))
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
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(unlocked ? Color("AppAccent").opacity(0.15) : Color("AppBackground").opacity(0.4))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, minHeight: 190)
        }
        .opacity(unlocked ? 1 : 0.75)
    }
}

struct SettingsActionCell: View {
    let title: String
    let systemImage: String
    var destructive: Bool = false

    var body: some View {
        SurfaceCard(padding: 14) {
            HStack(spacing: 14) {
                IconBadge(
                    systemName: systemImage,
                    size: 42,
                    tint: destructive ? Color.red : Color("AppPrimary")
                )
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(destructive ? Color.red : Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .frame(minHeight: 44)
        }
    }
}

struct StatsDashboardCell: View {
    let items: [(title: String, value: String, icon: String)]

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Your Activity")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items, id: \.title) { item in
                        VStack(spacing: 8) {
                            IconBadge(systemName: item.icon, size: 36)
                            Text(item.value)
                                .font(.headline)
                                .foregroundStyle(Color("AppPrimary"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(item.title)
                                .font(.caption2)
                                .foregroundStyle(Color("AppTextSecondary"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color("AppBackground").opacity(0.5), Color("AppSurface").opacity(0.35)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color("AppAccent").opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }
}

struct InsightBannerCell: View {
    let text: String

    var body: some View {
        SurfaceCard(accentBorder: true) {
            HStack(alignment: .top, spacing: 12) {
                IconBadge(systemName: "sparkles", size: 44)
                Text(text)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct EmptyStateCard: View {
    let symbolName: String
    let title: String
    let subtitle: String

    var body: some View {
        SurfaceCard {
            EmptyStateView(symbolName: symbolName, title: title, subtitle: subtitle)
                .padding(.vertical, 8)
        }
    }
}
