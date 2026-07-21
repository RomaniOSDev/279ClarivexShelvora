import Foundation
import Combine
import SwiftUI

final class ThemeExplorerViewModel: ObservableObject {
    @Published var selectedTheme: ThemeCollection?
    @Published var showDetail = false
    @Published var pulseThemeID: String?
    @Published var showSuccessCheck = false

    private let store: AppDataStore

    init(store: AppDataStore) {
        self.store = store
    }

    var themes: [ThemeCollection] { CuratedThemes.all }
    var favourites: [ThemeCollection] {
        themes.filter { store.favouriteThemes.contains($0.id) }
    }

    func open(_ theme: ThemeCollection) {
        FeedbackService.lightTap()
        store.markThemeViewed(theme.id)
        selectedTheme = theme
        showDetail = true
    }

    func preview(_ theme: ThemeCollection) {
        FeedbackService.lightTap()
        open(theme)
    }

    func toggleFavourite(_ theme: ThemeCollection) {
        FeedbackService.mediumTap()
        FeedbackService.successNotification()
        FeedbackService.playSaveTick()
        _ = store.toggleFavourite(themeId: theme.id)
        pulseThemeID = theme.id
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSuccessCheck = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.pulseThemeID = nil
        }
    }

    func removeFavourite(_ themeId: String) {
        FeedbackService.lightTap()
        FeedbackService.successNotification()
        FeedbackService.playSaveTick()
        store.removeFavourite(themeId: themeId)
    }

    func isFavourite(_ themeId: String) -> Bool {
        store.isFavourite(themeId)
    }
}
