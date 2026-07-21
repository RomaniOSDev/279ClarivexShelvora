import SwiftUI

struct ProjectsView: View {
    @ObservedObject var store: AppDataStore
    @State private var showCreate = false
    @State private var showTemplates = false
    @State private var showArchived = false
    @State private var draftName = ""
    @State private var draftNotes = ""
    @State private var draftTags = ""
    @State private var validationMessage: String?
    @State private var shakeTrigger: CGFloat = 0
    @State private var selectedTemplateId: String?

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 18) {
                    SurfaceCard(accentBorder: true) {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeaderView(
                                title: "Workspaces",
                                subtitle: "Projects hold frames, captions, and tags"
                            )
                            HStack(spacing: 10) {
                                PrimaryButton(title: "New Project") {
                                    selectedTemplateId = nil
                                    openCreate()
                                }
                                SecondaryButton(title: "Templates", systemImage: "square.grid.2x2") {
                                    showTemplates = true
                                }
                            }
                        }
                    }

                    SectionHeaderView(
                        title: "Active",
                        trailing: "\(store.activeProjects.count)"
                    )

                    if store.activeProjects.isEmpty {
                        EmptyStateCard(
                            symbolName: "folder.badge.plus",
                            title: "No projects yet",
                            subtitle: "Create a workspace or start from a template."
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(store.activeProjects) { project in
                                projectLink(project)
                            }
                        }
                    }

                    if !store.archivedProjects.isEmpty {
                        Button {
                            FeedbackService.lightTap()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showArchived.toggle()
                            }
                        } label: {
                            SectionHeaderView(
                                title: "Archived",
                                trailing: showArchived ? "Hide" : "\(store.archivedProjects.count)"
                            )
                        }
                        .buttonStyle(.plain)

                        if showArchived {
                            LazyVStack(spacing: 12) {
                                ForEach(store.archivedProjects) { project in
                                    projectLink(project)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .clearScrollBackground()
        }
        .navigationTitle("Projects")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: UUID.self) { id in
            StoryboardCanvasView(store: store, projectId: id)
        }
        .sheet(isPresented: $showCreate) { createSheet }
        .sheet(isPresented: $showTemplates) { templatesSheet }
    }

    private func projectLink(_ project: StoryProject) -> some View {
        NavigationLink(value: project.id) {
            ProjectWorkspaceCell(
                project: project,
                beatCount: store.frames(for: project.id).count
            )
        }
        .buttonStyle(ScalePressButtonStyle())
        .simultaneousGesture(TapGesture().onEnded {
            store.openProject(project.id)
        })
        .contextMenu {
            Button(project.isPinned ? "Unpin" : "Pin") { store.togglePin(projectId: project.id) }
            Button("Duplicate") {
                FeedbackService.mediumTap()
                _ = store.duplicateProject(id: project.id)
            }
            Button(project.isArchived ? "Unarchive" : "Archive") {
                store.toggleArchive(projectId: project.id)
            }
            Button("Delete", role: .destructive) { store.deleteProject(id: project.id) }
        }
    }

    private var createSheet: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 16) {
                        SurfaceCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Project name")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color("AppTextSecondary"))
                                TextField("Summer Trip", text: $draftName)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .modifier(ShakeEffect(animatableData: shakeTrigger))
                                if let validationMessage {
                                    Text(validationMessage)
                                        .font(.caption)
                                        .foregroundStyle(Color.red)
                                }
                            }
                        }
                        SurfaceCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Notes")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color("AppTextSecondary"))
                                TextField("What is this story about?", text: $draftNotes, axis: .vertical)
                                    .lineLimit(3...6)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text("Tags")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color("AppTextSecondary"))
                                TextField("coastal, night, family", text: $draftTags)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                if let selectedTemplateId,
                                   let theme = CuratedThemes.all.first(where: { $0.id == selectedTemplateId }) {
                                    TagChip(text: "Template: \(theme.name)", emphasized: true)
                                }
                            }
                        }
                        PrimaryButton(title: "Create Project") { createProject() }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        FeedbackService.lightTap()
                        showCreate = false
                    }
                }
            }
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
    }

    private var templatesSheet: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(CuratedThemes.all) { theme in
                            Button {
                                FeedbackService.lightTap()
                                selectedTemplateId = theme.id
                                store.markThemeViewed(theme.id)
                                showTemplates = false
                                openCreate(prefillName: theme.name)
                            } label: {
                                SurfaceCard(padding: 14) {
                                    HStack(spacing: 14) {
                                        IconBadge(systemName: theme.symbolName, size: 48)
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(theme.name)
                                                .font(.headline)
                                                .foregroundStyle(Color("AppTextPrimary"))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                            Text(theme.description)
                                                .font(.caption)
                                                .foregroundStyle(Color("AppTextSecondary"))
                                                .lineLimit(2)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(Color("AppPrimary"))
                                    }
                                }
                            }
                            .buttonStyle(ScalePressButtonStyle())
                        }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        FeedbackService.lightTap()
                        showTemplates = false
                    }
                }
            }
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func openCreate(prefillName: String? = nil) {
        draftName = prefillName ?? ""
        draftNotes = ""
        draftTags = ""
        validationMessage = nil
        showCreate = true
    }

    private func createProject() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            FeedbackService.warningNotification()
            validationMessage = "Please enter a project name."
            shakeTrigger = 0
            withAnimation(.default) { shakeTrigger = 1 }
            return
        }
        let tags = draftTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        FeedbackService.mediumTap()
        FeedbackService.completeMeaningfulAction()
        _ = store.createProject(
            name: trimmed,
            notes: draftNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: tags,
            templateId: selectedTemplateId
        )
        showCreate = false
    }
}
