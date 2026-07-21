import Foundation
import Combine
import SwiftUI

final class CaptionsViewModel: ObservableObject {
    @Published var showEditor = false
    @Published var editingItem: CaptionItem?
    @Published var draftText = ""
    @Published var draftSymbol = CaptionSymbolOption.all[0]
    @Published var draftBeat: CaptionBeatRole = .setup
    @Published var draftTone: CaptionTone = .warm
    @Published var draftVariants: [String] = ["", "", ""]
    @Published var selectedVariant = 0
    @Published var draftProjectId: UUID?
    @Published var draftFrameId: UUID?
    @Published var validationMessage: String?
    @Published var shakeTrigger: CGFloat = 0
    @Published var showSuccessCheck = false
    @Published var fadeInID: UUID?

    private let store: AppDataStore

    init(store: AppDataStore) {
        self.store = store
    }

    var captions: [CaptionItem] { store.captions }

    func openNew(prefillFromPrompt: Bool = false) {
        FeedbackService.lightTap()
        editingItem = nil
        draftText = prefillFromPrompt ? store.dailyPrompt() : ""
        draftSymbol = CaptionSymbolOption.all[0]
        draftBeat = .setup
        draftTone = .warm
        draftVariants = CaptionVariantFactory.makeVariants(base: draftText, beat: draftBeat, tone: draftTone)
        selectedVariant = 0
        draftProjectId = store.lastOpenedProjectID
        draftFrameId = nil
        validationMessage = nil
        showEditor = true
    }

    func openEdit(_ item: CaptionItem) {
        FeedbackService.lightTap()
        editingItem = item
        draftText = item.text
        draftSymbol = item.symbolName
        draftBeat = item.beatRole ?? .detail
        draftTone = item.tone ?? .warm
        draftVariants = item.variants.isEmpty
            ? CaptionVariantFactory.makeVariants(base: item.text, beat: item.beatRole, tone: item.tone)
            : item.variants
        selectedVariant = min(item.selectedVariantIndex, max(draftVariants.count - 1, 0))
        draftProjectId = item.projectId
        draftFrameId = item.frameId
        validationMessage = nil
        showEditor = true
    }

    func delete(_ item: CaptionItem) {
        FeedbackService.lightTap()
        store.deleteCaption(id: item.id)
    }

    func regenerateVariants() {
        FeedbackService.lightTap()
        draftVariants = CaptionVariantFactory.makeVariants(base: draftText, beat: draftBeat, tone: draftTone)
        selectedVariant = 0
    }

    func applyTemplateStructure() {
        FeedbackService.lightTap()
        let pieces = [
            CaptionBeatRole.setup.promptHint,
            CaptionBeatRole.conflict.promptHint,
            CaptionBeatRole.detail.promptHint,
            CaptionBeatRole.close.promptHint
        ]
        draftText = pieces.joined(separator: "\n\n")
        draftBeat = .setup
        regenerateVariants()
    }

    func save() {
        let chosen = draftVariants.indices.contains(selectedVariant)
            ? draftVariants[selectedVariant].trimmingCharacters(in: .whitespacesAndNewlines)
            : draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmed = chosen.isEmpty ? draftText.trimmingCharacters(in: .whitespacesAndNewlines) : chosen
        guard !trimmed.isEmpty else {
            FeedbackService.warningNotification()
            validationMessage = "Please enter a caption."
            shakeTrigger = 0
            withAnimation(.default) { shakeTrigger = 1 }
            return
        }

        FeedbackService.mediumTap()
        FeedbackService.playSaveTick()

        if var existing = editingItem {
            let history = existing.editHistory + [CaptionEditRecord(text: existing.text, timestamp: Date())]
            existing.text = trimmed
            existing.symbolName = draftSymbol
            existing.beatRole = draftBeat
            existing.tone = draftTone
            existing.variants = draftVariants
            existing.selectedVariantIndex = selectedVariant
            existing.editHistory = history
            existing.projectId = draftProjectId
            existing.frameId = draftFrameId
            store.updateCaption(existing)
            fadeInID = existing.id
        } else {
            let item = CaptionItem(
                text: trimmed,
                symbolName: draftSymbol,
                projectId: draftProjectId,
                frameId: draftFrameId,
                beatRole: draftBeat,
                tone: draftTone,
                variants: draftVariants,
                selectedVariantIndex: selectedVariant,
                editHistory: []
            )
            store.addCaption(item)
            fadeInID = item.id
        }

        showEditor = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSuccessCheck = true
        }
        FeedbackService.completeMeaningfulAction()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.fadeInID = nil
        }
    }
}
