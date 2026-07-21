import SwiftUI

struct CaptionsView: View {
    @ObservedObject var store: AppDataStore
    @StateObject private var viewModel: CaptionsViewModel

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    init(store: AppDataStore) {
        self.store = store
        _viewModel = StateObject(wrappedValue: CaptionsViewModel(store: store))
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        PromptHeroCell(prompt: store.dailyPrompt(), streakDays: store.streakDays)

                        SectionHeaderView(
                            title: "Caption Studio",
                            subtitle: "Structure, tone, variants, history",
                            trailing: "\(viewModel.captions.count)"
                        )

                        if viewModel.captions.isEmpty {
                            EmptyStateCard(
                                symbolName: "square.and.pencil",
                                title: "No captions yet",
                                subtitle: "Use story structure templates and tone presets."
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.captions) { item in
                                    Button {
                                        viewModel.openEdit(item)
                                    } label: {
                                        CaptionStudioCell(
                                            item: item,
                                            dateText: dateFormatter.string(from: item.timestamp)
                                        )
                                        .opacity(viewModel.fadeInID == item.id ? 0.45 : 1)
                                    }
                                    .buttonStyle(ScalePressButtonStyle())
                                    .contextMenu {
                                        Button("Edit") { viewModel.openEdit(item) }
                                        Button("Delete", role: .destructive) { viewModel.delete(item) }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .clearScrollBackground()

                SurfaceCard(padding: 12) {
                    HStack(spacing: 10) {
                        SecondaryButton(title: "From Prompt", systemImage: "lightbulb") {
                            viewModel.openNew(prefillFromPrompt: true)
                        }
                        PrimaryButton(title: "Add Caption") {
                            viewModel.openNew()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            SuccessCheckOverlay(isVisible: $viewModel.showSuccessCheck)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Caption Studio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $viewModel.showEditor) {
            captionEditor
        }
    }

    private var captionEditor: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                Form {
                    Section("Story Structure") {
                        Picker("Beat", selection: $viewModel.draftBeat) {
                            ForEach(CaptionBeatRole.allCases) { role in
                                Text(role.title).tag(role)
                            }
                        }
                        Text(viewModel.draftBeat.promptHint)
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                        Picker("Tone", selection: $viewModel.draftTone) {
                            ForEach(CaptionTone.allCases) { tone in
                                Text(tone.title).tag(tone)
                            }
                        }
                        Button("Insert Setup → Conflict → Detail → Close") {
                            viewModel.applyTemplateStructure()
                        }
                        .foregroundStyle(Color("AppPrimary"))
                    }

                    Section("Caption") {
                        TextField("Caption", text: $viewModel.draftText, axis: .vertical)
                            .lineLimit(3...8)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .modifier(ShakeEffect(animatableData: viewModel.shakeTrigger))

                        if let message = viewModel.validationMessage {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(Color.red)
                        }

                        Picker("Thumbnail", selection: $viewModel.draftSymbol) {
                            ForEach(CaptionSymbolOption.all, id: \.self) { symbol in
                                Label(symbol.capitalized, systemImage: symbol).tag(symbol)
                            }
                        }
                    }

                    Section("Variants") {
                        Button("Generate 3 Variants") {
                            viewModel.regenerateVariants()
                        }
                        .foregroundStyle(Color("AppPrimary"))

                        ForEach(viewModel.draftVariants.indices, id: \.self) { index in
                            Button {
                                FeedbackService.lightTap()
                                viewModel.selectedVariant = index
                            } label: {
                                HStack(alignment: .top) {
                                    Image(systemName: viewModel.selectedVariant == index ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(Color("AppPrimary"))
                                    TextField("Variant \(index + 1)", text: $viewModel.draftVariants[index], axis: .vertical)
                                        .foregroundStyle(Color("AppTextPrimary"))
                                }
                            }
                        }
                    }

                    Section("Link") {
                        Picker("Project", selection: $viewModel.draftProjectId) {
                            Text("None").tag(Optional<UUID>.none)
                            ForEach(store.activeProjects) { project in
                                Text(project.name).tag(Optional(project.id))
                            }
                        }
                        if let projectId = viewModel.draftProjectId {
                            Picker("Frame", selection: $viewModel.draftFrameId) {
                                Text("None").tag(Optional<UUID>.none)
                                ForEach(store.frames(for: projectId)) { frame in
                                    Text(frame.title).tag(Optional(frame.id))
                                }
                            }
                        }
                    }

                    if let history = viewModel.editingItem?.editHistory, !history.isEmpty {
                        Section("Edit History") {
                            ForEach(Array(history.suffix(8).reversed().enumerated()), id: \.offset) { _, record in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(record.text)
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .font(.subheadline)
                                    Text(dateFormatter.string(from: record.timestamp))
                                        .font(.caption2)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(viewModel.editingItem == nil ? "New Caption" : "Edit Caption")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        FeedbackService.lightTap()
                        viewModel.showEditor = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { viewModel.save() }
                }
            }
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: viewModel.draftBeat) { _ in viewModel.regenerateVariants() }
            .onChange(of: viewModel.draftTone) { _ in viewModel.regenerateVariants() }
        }
        .presentationDetents([.large])
    }
}
