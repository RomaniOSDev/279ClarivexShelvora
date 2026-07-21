import SwiftUI

struct HomeView: View {
    @ObservedObject var store: AppDataStore
    @State private var searchText = ""
    @State private var filterTag = ""
    @State private var selectedStack: SmartStackKind?
    @State private var showDateFilter = false
    @State private var showSearchPanel = false
    @State private var fromDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var toDate = Date()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 20) {
                        heroSection
                        featureRail
                        quickActions

                        SectionHeaderView(
                            title: "Smart Stacks",
                            subtitle: "Jump into unfinished work",
                            trailing: selectedStack?.title
                        )
                        smartStacks

                        if showSearchPanel {
                            SectionHeaderView(title: "Find Beats", subtitle: "Search by text, tag, or date")
                            searchBlock
                        }

                        SectionHeaderView(
                            title: selectedStack?.title ?? (showSearchPanel ? "Results" : "Recent Beats"),
                            trailing: "\(displayedFrames().count)"
                        )
                        resultsBlock
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, TabBarMetrics.clearance)
                }
                .clearScrollBackground()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: UUID.self) { projectId in
                StoryboardCanvasView(store: store, projectId: projectId)
            }
        }
        .transparentScreenChrome()
    }

    private var heroSection: some View {
        HomeHeroBanner(
            prompt: store.dailyPrompt(),
            streakDays: store.streakDays,
            projectCount: store.activeProjects.count,
            frameCount: store.frames.count,
            onContinue: store.lastOpenedProject == nil ? nil : {
                if let id = store.lastOpenedProject?.id {
                    store.openProject(id)
                    path.append(id)
                }
            }
        )
    }

    private var featureRail: some View {
        VStack(spacing: 12) {
            if let project = store.lastOpenedProject {
                Button {
                    FeedbackService.lightTap()
                    store.openProject(project.id)
                    path.append(project.id)
                } label: {
                    HomeImageFeatureCard(
                        imageName: "HomeContinue",
                        title: project.name,
                        subtitle: "\(store.frames(for: project.id).count) beats · Continue canvas",
                        badge: "Resume"
                    )
                }
                .buttonStyle(ScalePressButtonStyle())
            } else {
                HomeImageFeatureCard(
                    imageName: "HomeContinue",
                    title: "Start a storyboard",
                    subtitle: "Create a project in Studio to unlock resume",
                    badge: "New"
                )
            }

            HStack(spacing: 12) {
                Button {
                    FeedbackService.lightTap()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedStack = .unfinished
                        showSearchPanel = false
                    }
                } label: {
                    HomeImageFeatureCard(
                        imageName: "HomeStacks",
                        title: "Smart Stacks",
                        subtitle: "\(store.smartStackCount(.unfinished)) open gaps",
                        badge: "Queue"
                    )
                }
                .buttonStyle(ScalePressButtonStyle())

                Button {
                    FeedbackService.lightTap()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showSearchPanel.toggle()
                        if showSearchPanel { selectedStack = nil }
                    }
                } label: {
                    HomeImageFeatureCard(
                        imageName: "HomeSearch",
                        title: "Find Beats",
                        subtitle: showSearchPanel ? "Search open" : "Tag · date · text",
                        badge: "Search"
                    )
                }
                .buttonStyle(ScalePressButtonStyle())
            }
        }
    }

    private var quickActions: some View {
        VStack(spacing: 10) {
            SectionHeaderView(title: "Quick Actions", subtitle: "Most useful next steps")

            if let insight = store.selectedInsightTag {
                Button {
                    FeedbackService.lightTap()
                    store.selectedInsightTag = nil
                } label: {
                    HomeQuickActionCell(
                        title: "Clear insight filter",
                        subtitle: "Currently filtering: \(insight)",
                        systemImage: "line.3.horizontal.decrease.circle"
                    )
                }
                .buttonStyle(ScalePressButtonStyle())
            }

            Button {
                FeedbackService.lightTap()
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedStack = .needsCaption
                    showSearchPanel = false
                }
            } label: {
                HomeQuickActionCell(
                    title: "Caption missing beats",
                    subtitle: "\(store.smartStackCount(.needsCaption)) frames wait for copy",
                    systemImage: "text.badge.plus"
                )
            }
            .buttonStyle(ScalePressButtonStyle())

            Button {
                FeedbackService.lightTap()
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedStack = .untagged
                    showSearchPanel = false
                }
            } label: {
                HomeQuickActionCell(
                    title: "Tag untagged frames",
                    subtitle: "\(store.smartStackCount(.untagged)) beats without labels",
                    systemImage: "tag"
                )
            }
            .buttonStyle(ScalePressButtonStyle())
        }
    }

    private var smartStacks: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(SmartStackKind.allCases) { kind in
                Button {
                    FeedbackService.lightTap()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedStack = selectedStack == kind ? nil : kind
                        showSearchPanel = false
                    }
                } label: {
                    SmartStackCell(kind: kind, count: store.smartStackCount(kind), selected: selectedStack == kind)
                }
                .buttonStyle(ScalePressButtonStyle())
            }
        }
    }

    private var searchBlock: some View {
        SurfaceCard {
            VStack(spacing: 12) {
                AppTextField(placeholder: "Search title or tag", text: $searchText, icon: "magnifyingglass")
                AppTextField(placeholder: "Filter by tag", text: $filterTag, icon: "tag")

                if let insightTag = store.selectedInsightTag, filterTag.isEmpty {
                    HStack {
                        TagChip(text: "Insight: \(insightTag)", emphasized: true)
                        Spacer()
                        Button("Clear") {
                            FeedbackService.lightTap()
                            store.selectedInsightTag = nil
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppPrimary"))
                        .frame(minHeight: 44)
                    }
                }

                Toggle(isOn: $showDateFilter) {
                    Text("Date range")
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                .tint(Color("AppPrimary"))

                if showDateFilter {
                    DatePicker("From", selection: $fromDate, displayedComponents: .date)
                        .colorScheme(.dark)
                    DatePicker("To", selection: $toDate, displayedComponents: .date)
                        .colorScheme(.dark)
                }
            }
        }
    }

    @ViewBuilder
    private var resultsBlock: some View {
        let frames = displayedFrames()
        if frames.isEmpty {
            EmptyStateCard(
                symbolName: "magnifyingglass",
                title: "No matching beats",
                subtitle: "Create a project and add frames to fill this feed."
            )
        } else {
            LazyVStack(spacing: 12) {
                ForEach(frames.prefix(12)) { frame in
                    Button {
                        FeedbackService.lightTap()
                        store.openProject(frame.projectId)
                        path.append(frame.projectId)
                    } label: {
                        BeatResultCell(
                            frame: frame,
                            projectName: store.project(id: frame.projectId)?.name
                        )
                    }
                    .buttonStyle(ScalePressButtonStyle())
                }
            }
        }
    }

    private func displayedFrames() -> [StoryFrame] {
        if let stack = selectedStack {
            return store.smartStackFrames(stack)
        }
        if showSearchPanel {
            let tag = filterTag.isEmpty ? store.selectedInsightTag : filterTag
            return store.searchFrames(
                query: searchText,
                tag: tag,
                projectId: nil,
                from: showDateFilter ? fromDate : nil,
                to: showDateFilter ? toDate : nil
            )
        }
        if let insight = store.selectedInsightTag {
            return store.searchFrames(query: "", tag: insight, projectId: nil, from: nil, to: nil)
        }
        return store.frames.sorted { $0.createdAt > $1.createdAt }
    }
}
