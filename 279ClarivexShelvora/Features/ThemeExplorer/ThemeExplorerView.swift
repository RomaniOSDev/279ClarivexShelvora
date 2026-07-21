import SwiftUI

struct ThemeExplorerView: View {
    @ObservedObject var store: AppDataStore
    @StateObject private var viewModel: ThemeExplorerViewModel

    init(store: AppDataStore) {
        self.store = store
        _viewModel = StateObject(wrappedValue: ThemeExplorerViewModel(store: store))
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            List {
                Section {
                    EmptyStateView(
                        symbolName: "photo.on.rectangle",
                        title: "Discover New Themes",
                        subtitle: "Explore Curated Themes Here!"
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                if !viewModel.favourites.isEmpty {
                    Section("Favourites") {
                        ForEach(viewModel.favourites) { theme in
                            themeCard(theme)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.removeFavourite(theme.id)
                                    } label: {
                                        Label("Remove", systemImage: "heart.slash")
                                    }
                                }
                        }
                    }
                }

                Section("Collections") {
                    ForEach(viewModel.themes) { theme in
                        themeCard(theme)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .contextMenu {
                                Button("Preview") { viewModel.preview(theme) }
                                Button(viewModel.isFavourite(theme.id) ? "Remove Favourite" : "Add to Favourites") {
                                    viewModel.toggleFavourite(theme)
                                }
                            }
                    }
                }
            }
            .listStyle(.plain)
            .clearScrollBackground()
            .padding(.bottom, 8)

            SuccessCheckOverlay(isVisible: $viewModel.showSuccessCheck)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Theme Explorer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $viewModel.showDetail) {
            if let theme = viewModel.selectedTheme {
                themeDetail(theme)
            }
        }
    }

    private func themeCard(_ theme: ThemeCollection) -> some View {
        Button {
            viewModel.open(theme)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                ThemeCoverView(theme: theme)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(theme.name)
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(theme.description)
                            .font(.subheadline)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineLimit(2)
                    }
                    Spacer()
                    if viewModel.isFavourite(theme.id) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Color("AppPrimary"))
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(viewModel.pulseThemeID == theme.id ? Color("AppAccent").opacity(0.35) : Color("AppSurface"))
            )
            .animation(.easeInOut(duration: 0.4), value: viewModel.pulseThemeID)
        }
        .buttonStyle(.plain)
    }

    private func themeDetail(_ theme: ThemeCollection) -> some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ThemeCoverView(theme: theme)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        Text(theme.name)
                            .font(.title2.bold())
                            .foregroundStyle(Color("AppTextPrimary"))

                        Text(theme.description)
                            .font(.body)
                            .foregroundStyle(Color("AppTextSecondary"))

                        Text("Suggested frames")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(0..<6, id: \.self) { index in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color("AppSurface"))
                                    Image(systemName: theme.symbolName)
                                        .font(.title3)
                                        .foregroundStyle(Color("AppAccent").opacity(0.7 + Double(index) * 0.05))
                                }
                                .frame(height: 72)
                            }
                        }

                        PrimaryButton(title: viewModel.isFavourite(theme.id) ? "Remove from Favourites" : "Add to Favourites") {
                            viewModel.toggleFavourite(theme)
                        }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        FeedbackService.lightTap()
                        viewModel.showDetail = false
                    }
                }
            }
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct ThemeCoverView: View {
    let theme: ThemeCollection

    var body: some View {
        ZStack {
            LinearGradient(
                colors: coverColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Canvas { context, size in
                for i in 0..<5 {
                    let inset = CGFloat(i) * 12
                    let rect = CGRect(
                        x: inset,
                        y: inset,
                        width: size.width - inset * 2,
                        height: size.height - inset * 2
                    )
                    context.stroke(
                        Path(roundedRect: rect, cornerRadius: 12),
                        with: .color(Color("AppTextPrimary").opacity(0.08)),
                        lineWidth: 1
                    )
                }
            }
            .allowsHitTesting(false)

            Image(systemName: theme.symbolName)
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(Color("AppTextPrimary").opacity(0.9))
        }
    }

    private var coverColors: [Color] {
        switch theme.accentIndex % 6 {
        case 0: return [Color("AppPrimary").opacity(0.55), Color("AppSurface")]
        case 1: return [Color("AppAccent").opacity(0.45), Color("AppBackground")]
        case 2: return [Color("AppSurface"), Color("AppPrimary").opacity(0.35)]
        case 3: return [Color("AppBackground"), Color("AppAccent").opacity(0.4)]
        case 4: return [Color("AppPrimary").opacity(0.3), Color("AppAccent").opacity(0.25)]
        default: return [Color("AppSurface"), Color("AppBackground")]
        }
    }
}
