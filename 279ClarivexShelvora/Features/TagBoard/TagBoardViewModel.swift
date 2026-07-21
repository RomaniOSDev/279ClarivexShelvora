import Foundation
import Combine
import SwiftUI

final class TagBoardViewModel: ObservableObject {
    @Published var showEditor = false
    @Published var editingEntry: TagEntry?
    @Published var draftTitle = ""
    @Published var draftIcon = TagIconOption.all[0]
    @Published var validationMessage: String?
    @Published var shakeTrigger: CGFloat = 0
    @Published var recentlyAddedID: UUID?
    @Published var showSuccessCheck = false

    private let store: AppDataStore

    init(store: AppDataStore) {
        self.store = store
    }

    var entries: [TagEntry] { store.entries }

    func openNew() {
        FeedbackService.lightTap()
        editingEntry = nil
        draftTitle = ""
        draftIcon = TagIconOption.all[0]
        validationMessage = nil
        showEditor = true
    }

    func openEdit(_ entry: TagEntry) {
        FeedbackService.lightTap()
        editingEntry = entry
        draftTitle = entry.title
        draftIcon = entry.icon
        validationMessage = nil
        showEditor = true
    }

    func delete(_ entry: TagEntry) {
        FeedbackService.lightTap()
        store.deleteEntry(id: entry.id)
    }

    func save() {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            FeedbackService.warningNotification()
            validationMessage = "Please enter a title."
            withShake()
            return
        }

        FeedbackService.mediumTap()
        FeedbackService.softSuccess()
        FeedbackService.playEntrySaved()

        if var existing = editingEntry {
            existing.title = trimmed
            existing.icon = draftIcon
            store.updateEntry(existing)
            recentlyAddedID = existing.id
        } else {
            let entry = TagEntry(title: trimmed, icon: draftIcon)
            store.addEntry(entry)
            recentlyAddedID = entry.id
        }

        showEditor = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSuccessCheck = true
        }
        FeedbackService.completeMeaningfulAction()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.recentlyAddedID = nil
        }
    }

    private func withShake() {
        shakeTrigger = 0
        withAnimation(.default) {
            shakeTrigger = 1
        }
    }
}
