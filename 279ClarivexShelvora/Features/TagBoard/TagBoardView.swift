import SwiftUI

struct TagBoardView: View {
    @ObservedObject var store: AppDataStore
    @StateObject private var viewModel: TagBoardViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(store: AppDataStore) {
        self.store = store
        _viewModel = StateObject(wrappedValue: TagBoardViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 18) {
                            if viewModel.entries.isEmpty {
                                EmptyStateView(
                                    symbolName: "tag.circle",
                                    title: "Start organizing your stories",
                                    subtitle: "Organize your stories by adding entries with tags and icons!"
                                )
                                TagPlaceholderIllustration()
                            } else {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(viewModel.entries) { entry in
                                        entryCard(entry)
                                            .scaleEffect(viewModel.recentlyAddedID == entry.id ? 1.06 : 1)
                                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.recentlyAddedID)
                                            .contextMenu {
                                                Button("Edit") { viewModel.openEdit(entry) }
                                                Button("Delete", role: .destructive) { viewModel.delete(entry) }
                                            }
                                    }
                                }

                                List {
                                    ForEach(viewModel.entries) { entry in
                                        Text(entry.title)
                                            .foregroundStyle(Color("AppTextPrimary"))
                                            .listRowBackground(Color("AppSurface"))
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    viewModel.delete(entry)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                            .onTapGesture {
                                                viewModel.openEdit(entry)
                                            }
                                    }
                                }
                                .listStyle(.insetGrouped)
                                .clearScrollBackground()
                                .frame(minHeight: CGFloat(min(viewModel.entries.count, 4)) * 52 + 24)
                                .frame(maxHeight: 240)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                    }
                    .clearScrollBackground()

                    PrimaryButton(title: "Add New Entry") {
                        viewModel.openNew()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, TabBarMetrics.clearance)
                    .padding(.top, 8)
                }

                SuccessCheckOverlay(isVisible: $viewModel.showSuccessCheck)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Tag Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $viewModel.showEditor) {
                entryEditor
            }
        }
        .transparentScreenChrome()
    }

    private func entryCard(_ entry: TagEntry) -> some View {
        VStack(spacing: 10) {
            Text(entry.icon)
                .font(.system(size: 36))
            Text(entry.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            store.lastViewedEntryID = entry.id
            viewModel.openEdit(entry)
        }
    }

    private var entryEditor: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                Form {
                    Section {
                        TextField("Title", text: $viewModel.draftTitle)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .modifier(ShakeEffect(animatableData: viewModel.shakeTrigger))

                        if let message = viewModel.validationMessage {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(Color.red)
                        }

                        Picker("Icon", selection: $viewModel.draftIcon) {
                            ForEach(TagIconOption.all, id: \.self) { icon in
                                Text(icon).tag(icon)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(viewModel.editingEntry == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        FeedbackService.lightTap()
                        viewModel.showEditor = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                    }
                }
            }
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
    }
}

private struct TagPlaceholderIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color("AppSurface"))
                .frame(height: 140)

            Canvas { context, size in
                let tag = Path { path in
                    path.move(to: CGPoint(x: size.width * 0.28, y: size.height * 0.35))
                    path.addLine(to: CGPoint(x: size.width * 0.48, y: size.height * 0.2))
                    path.addLine(to: CGPoint(x: size.width * 0.58, y: size.height * 0.35))
                    path.addLine(to: CGPoint(x: size.width * 0.38, y: size.height * 0.5))
                    path.closeSubpath()
                }
                context.fill(tag, with: .color(Color("AppPrimary").opacity(0.35)))

                let glass = Path(ellipseIn: CGRect(x: size.width * 0.52, y: size.height * 0.38, width: 46, height: 46))
                context.stroke(glass, with: .color(Color("AppAccent")), lineWidth: 3)
                var handle = Path()
                handle.move(to: CGPoint(x: size.width * 0.52 + 38, y: size.height * 0.38 + 38))
                handle.addLine(to: CGPoint(x: size.width * 0.52 + 54, y: size.height * 0.38 + 54))
                context.stroke(handle, with: .color(Color("AppAccent")), lineWidth: 3)
            }
            .frame(height: 140)
            .allowsHitTesting(false)
        }
    }
}
