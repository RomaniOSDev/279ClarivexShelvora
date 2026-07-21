import SwiftUI

struct StoryboardCanvasView: View {
    @ObservedObject var store: AppDataStore
    let projectId: UUID

    @State private var showAddFrame = false
    @State private var showShare = false
    @State private var editingFrame: StoryFrame?
    @State private var draftTitle = ""
    @State private var draftIcon = TagIconOption.all[0]
    @State private var draftDuration = 4
    @State private var draftTags = ""
    @State private var validationMessage: String?
    @State private var shakeTrigger: CGFloat = 0
    @State private var showSuccess = false
    @State private var linkSourceID: UUID?

    private var project: StoryProject? { store.project(id: projectId) }
    private var projectFrames: [StoryFrame] { store.frames(for: projectId) }

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 18) {
                    if let project {
                        header(project)
                        layoutPicker(project)
                        SectionHeaderView(
                            title: "Canvas",
                            subtitle: layoutHint(project.preferredLayout),
                            trailing: linkSourceID == nil ? nil : "Linking…"
                        )
                        canvas(project)
                        beatOrderSection
                    } else {
                        EmptyStateCard(
                            symbolName: "film",
                            title: "Project missing",
                            subtitle: "Return home and open another project."
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .clearScrollBackground()

            SuccessCheckOverlay(isVisible: $showSuccess)
        }
        .navigationTitle("Storyboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    FeedbackService.lightTap()
                    showShare = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    FeedbackService.lightTap()
                    openNewFrame()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
        .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showAddFrame) { frameEditor }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [store.exportScript(for: projectId)])
        }
        .onAppear {
            store.openProject(projectId)
        }
    }

    private func header(_ project: StoryProject) -> some View {
        let total = projectFrames.reduce(0) { $0 + $1.durationSeconds }
        return SurfaceCard(accentBorder: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    IconBadge(systemName: "film", size: 52)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.name)
                            .font(.title2.bold())
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        if !project.notes.isEmpty {
                            Text(project.notes)
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextSecondary"))
                                .lineLimit(3)
                        }
                    }
                }
                HStack(spacing: 8) {
                    TagChip(text: "\(projectFrames.count) beats", emphasized: true)
                    TagChip(text: "\(total)s runtime")
                    if project.isPinned {
                        TagChip(text: "Pinned")
                    }
                }
                if !project.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(project.tags, id: \.self) { tag in
                                TagChip(text: tag)
                            }
                        }
                    }
                }
                PrimaryButton(title: "Add Beat") { openNewFrame() }
            }
        }
    }

    private func layoutPicker(_ project: StoryProject) -> some View {
        SurfaceCard(padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Layout")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppTextSecondary"))
                Picker("Layout", selection: Binding(
                    get: { project.preferredLayout },
                    set: {
                        FeedbackService.lightTap()
                        store.setLayout($0, for: projectId)
                    }
                )) {
                    ForEach(StoryboardLayout.allCases) { layout in
                        Text(layout.title).tag(layout)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    @ViewBuilder
    private func canvas(_ project: StoryProject) -> some View {
        if projectFrames.isEmpty {
            EmptyStateCard(
                symbolName: "rectangle.stack.badge.plus",
                title: "Empty canvas",
                subtitle: "Add your first beat to build the story."
            )
        } else {
            switch project.preferredLayout {
            case .grid2x2:
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(Array(projectFrames.enumerated()), id: \.element.id) { index, frame in
                        beatButton(frame, index: index)
                    }
                }
            case .filmstrip:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(projectFrames.enumerated()), id: \.element.id) { index, frame in
                            beatButton(frame, index: index)
                                .frame(width: 220)
                            if index < projectFrames.count - 1 {
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(Color("AppAccent"))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            case .vertical:
                LazyVStack(spacing: 10) {
                    ForEach(Array(projectFrames.enumerated()), id: \.element.id) { index, frame in
                        beatButton(frame, index: index)
                        if index < projectFrames.count - 1 {
                            Image(systemName: "arrow.down")
                                .foregroundStyle(Color("AppAccent"))
                        }
                    }
                }
            }
        }
    }

    private func beatButton(_ frame: StoryFrame, index: Int) -> some View {
        let nextTitle = frame.nextFrameId.flatMap { id in projectFrames.first(where: { $0.id == id })?.title }
        return Button {
            FeedbackService.lightTap()
            openEdit(frame)
        } label: {
            StoryboardBeatCell(frame: frame, index: index, nextTitle: nextTitle)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(linkSourceID == frame.id ? Color("AppPrimary") : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(ScalePressButtonStyle())
        .contextMenu {
            Button("Edit") { openEdit(frame) }
            Button(linkSourceID == frame.id ? "Cancel Link" : "Set as Link Source") {
                FeedbackService.lightTap()
                linkSourceID = linkSourceID == frame.id ? nil : frame.id
            }
            if let source = linkSourceID, source != frame.id {
                Button("Link Previous Beat Here") {
                    FeedbackService.mediumTap()
                    store.linkFrames(from: source, to: frame.id)
                    linkSourceID = nil
                    withAnimation { showSuccess = true }
                }
            }
            Button("Clear Next Link") {
                store.linkFrames(from: frame.id, to: nil)
            }
            Button("Delete", role: .destructive) {
                store.deleteFrame(id: frame.id)
            }
        }
    }

    private var beatOrderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Beat Order", subtitle: "Drag handles to reorder")

            SurfaceCard(padding: 8) {
                List {
                    ForEach(projectFrames) { frame in
                        HStack(spacing: 12) {
                            EmojiBadge(emoji: frame.icon, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(frame.title)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text("\(frame.durationSeconds)s")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                        .swipeActions {
                            Button(role: .destructive) {
                                store.deleteFrame(id: frame.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onMove { indices, newOffset in
                        store.moveFrame(projectId: projectId, fromOffsets: indices, toOffset: newOffset)
                    }
                }
                .environment(\.editMode, .constant(.active))
                .listStyle(.plain)
                .clearScrollBackground()
                .frame(minHeight: CGFloat(max(projectFrames.count, 1)) * 64 + 16)
                .frame(maxHeight: 300)
            }
        }
    }

    private var frameEditor: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 16) {
                        SurfaceCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Beat title")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color("AppTextSecondary"))
                                TextField("Opening light", text: $draftTitle)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .modifier(ShakeEffect(animatableData: shakeTrigger))
                                if let validationMessage {
                                    Text(validationMessage)
                                        .font(.caption)
                                        .foregroundStyle(Color.red)
                                }
                                Stepper("Duration: \(draftDuration)s", value: $draftDuration, in: 1...120)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                TextField("Tags (comma separated)", text: $draftTags)
                                    .foregroundStyle(Color("AppTextPrimary"))
                            }
                        }
                        SurfaceCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Icon")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color("AppTextSecondary"))
                                Picker("Icon", selection: $draftIcon) {
                                    ForEach(TagIconOption.all, id: \.self) { icon in
                                        Text(icon).tag(icon)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 110)
                            }
                        }
                        PrimaryButton(title: "Save Beat") { saveFrame() }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle(editingFrame == nil ? "New Beat" : "Edit Beat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        FeedbackService.lightTap()
                        showAddFrame = false
                    }
                }
            }
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
    }

    private func layoutHint(_ layout: StoryboardLayout) -> String {
        switch layout {
        case .grid2x2: return "Compact overview grid"
        case .filmstrip: return "Horizontal sequence with arrows"
        case .vertical: return "Top-to-bottom story flow"
        }
    }

    private func openNewFrame() {
        editingFrame = nil
        draftTitle = ""
        draftIcon = TagIconOption.all[0]
        draftDuration = 4
        draftTags = ""
        validationMessage = nil
        showAddFrame = true
    }

    private func openEdit(_ frame: StoryFrame) {
        editingFrame = frame
        draftTitle = frame.title
        draftIcon = frame.icon
        draftDuration = frame.durationSeconds
        draftTags = frame.tags.joined(separator: ", ")
        validationMessage = nil
        showAddFrame = true
    }

    private func saveFrame() {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            FeedbackService.warningNotification()
            validationMessage = "Please enter a beat title."
            shakeTrigger = 0
            withAnimation(.default) { shakeTrigger = 1 }
            return
        }
        let tags = draftTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        FeedbackService.mediumTap()
        FeedbackService.playEntrySaved()

        if var existing = editingFrame {
            existing.title = trimmed
            existing.icon = draftIcon
            existing.durationSeconds = draftDuration
            existing.tags = tags
            store.updateFrame(existing)
        } else {
            store.addFrame(
                to: projectId,
                title: trimmed,
                icon: draftIcon,
                durationSeconds: draftDuration,
                tags: tags
            )
        }
        showAddFrame = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSuccess = true
        }
        FeedbackService.completeMeaningfulAction()
    }
}
