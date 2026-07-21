import Foundation
import Combine

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    @Published var hasSeenOnboarding: Bool {
        didSet { defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding) }
    }

    @Published var totalSessionsCompleted: Int {
        didSet { defaults.set(totalSessionsCompleted, forKey: Keys.totalSessionsCompleted) }
    }

    @Published var totalMinutesUsed: Int {
        didSet { defaults.set(totalMinutesUsed, forKey: Keys.totalMinutesUsed) }
    }

    @Published var streakDays: Int {
        didSet { defaults.set(streakDays, forKey: Keys.streakDays) }
    }

    @Published var lastActivityDate: Date? {
        didSet { defaults.set(lastActivityDate, forKey: Keys.lastActivityDate) }
    }

    @Published var achievementsUnlocked: [String: Date] {
        didSet { saveCodable(achievementsUnlocked, key: Keys.achievementsUnlocked) }
    }

    @Published var entries: [TagEntry] {
        didSet {
            saveCodable(entries, key: Keys.entries)
            entryCount = entries.count
        }
    }

    @Published var lastViewedEntryID: UUID? {
        didSet { defaults.set(lastViewedEntryID?.uuidString, forKey: Keys.lastViewedEntryID) }
    }

    @Published var entryCount: Int {
        didSet { defaults.set(entryCount, forKey: Keys.entryCount) }
    }

    @Published var itemsAdded: Int {
        didSet { defaults.set(itemsAdded, forKey: Keys.itemsAdded) }
    }

    @Published var entriesWritten: Int {
        didSet { defaults.set(entriesWritten, forKey: Keys.entriesWritten) }
    }

    @Published var favouritesCount: Int {
        didSet { defaults.set(favouritesCount, forKey: Keys.favouritesCount) }
    }

    @Published var captions: [CaptionItem] {
        didSet { saveCodable(captions, key: Keys.captions) }
    }

    @Published var currentThemeId: Int {
        didSet { defaults.set(currentThemeId, forKey: Keys.currentThemeId) }
    }

    @Published var favouriteThemes: [String] {
        didSet { defaults.set(favouriteThemes, forKey: Keys.favouriteThemes) }
    }

    @Published var viewedThemeIds: [String] {
        didSet { defaults.set(viewedThemeIds, forKey: Keys.viewedThemeIds) }
    }

    @Published var projects: [StoryProject] {
        didSet { saveCodable(projects, key: Keys.projects) }
    }

    @Published var frames: [StoryFrame] {
        didSet { saveCodable(frames, key: Keys.frames) }
    }

    @Published var lastOpenedProjectID: UUID? {
        didSet { defaults.set(lastOpenedProjectID?.uuidString, forKey: Keys.lastOpenedProjectID) }
    }

    @Published var selectedInsightTag: String? {
        didSet { defaults.set(selectedInsightTag, forKey: Keys.selectedInsightTag) }
    }

    @Published var pendingAchievementIDs: [String] = []

    private var minuteAccumulator: TimeInterval = 0
    private var lastMinuteTick: Date?

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let totalSessionsCompleted = "totalSessionsCompleted"
        static let totalMinutesUsed = "totalMinutesUsed"
        static let streakDays = "streakDays"
        static let lastActivityDate = "lastActivityDate"
        static let achievementsUnlocked = "achievementsUnlocked"
        static let entries = "entries"
        static let lastViewedEntryID = "lastViewedEntryID"
        static let entryCount = "entryCount"
        static let itemsAdded = "itemsAdded"
        static let entriesWritten = "entriesWritten"
        static let favouritesCount = "favouritesCount"
        static let captions = "captions"
        static let currentThemeId = "currentThemeId"
        static let favouriteThemes = "favouriteThemes"
        static let viewedThemeIds = "viewedThemeIds"
        static let projects = "projects"
        static let frames = "frames"
        static let lastOpenedProjectID = "lastOpenedProjectID"
        static let selectedInsightTag = "selectedInsightTag"
    }

    private init() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        totalSessionsCompleted = defaults.integer(forKey: Keys.totalSessionsCompleted)
        totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        streakDays = defaults.integer(forKey: Keys.streakDays)
        lastActivityDate = defaults.object(forKey: Keys.lastActivityDate) as? Date
        achievementsUnlocked = Self.loadCodable([String: Date].self, key: Keys.achievementsUnlocked) ?? [:]
        itemsAdded = defaults.integer(forKey: Keys.itemsAdded)
        entriesWritten = defaults.integer(forKey: Keys.entriesWritten)
        favouritesCount = defaults.integer(forKey: Keys.favouritesCount)
        captions = Self.loadCodable([CaptionItem].self, key: Keys.captions) ?? []
        currentThemeId = defaults.integer(forKey: Keys.currentThemeId)
        favouriteThemes = defaults.stringArray(forKey: Keys.favouriteThemes) ?? []
        viewedThemeIds = defaults.stringArray(forKey: Keys.viewedThemeIds) ?? []
        projects = Self.loadCodable([StoryProject].self, key: Keys.projects) ?? []
        frames = Self.loadCodable([StoryFrame].self, key: Keys.frames) ?? []
        selectedInsightTag = defaults.string(forKey: Keys.selectedInsightTag)

        let loadedEntries = Self.loadCodable([TagEntry].self, key: Keys.entries) ?? []
        entryCount = defaults.object(forKey: Keys.entryCount) as? Int ?? loadedEntries.count
        entries = loadedEntries
        if let idString = defaults.string(forKey: Keys.lastViewedEntryID) {
            lastViewedEntryID = UUID(uuidString: idString)
        } else {
            lastViewedEntryID = nil
        }
        if let projectString = defaults.string(forKey: Keys.lastOpenedProjectID) {
            lastOpenedProjectID = UUID(uuidString: projectString)
        } else {
            lastOpenedProjectID = nil
        }

        NotificationCenter.default.publisher(for: .dataReset)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reloadFromDefaults()
            }
            .store(in: &cancellables)
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        hasSeenOnboarding = true
    }

    // MARK: - Legacy tag entries

    func addEntry(_ entry: TagEntry) {
        entries.insert(entry, at: 0)
        lastViewedEntryID = entry.id
        itemsAdded += 1
        entriesWritten += 1
        totalSessionsCompleted += 1
        recordActivity()
        evaluateAchievements()
    }

    func updateEntry(_ entry: TagEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = entry
        lastViewedEntryID = entry.id
        recordActivity()
    }

    func deleteEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        if lastViewedEntryID == id {
            lastViewedEntryID = entries.first?.id
        }
    }

    // MARK: - Captions

    func addCaption(_ item: CaptionItem) {
        captions.insert(item, at: 0)
        entriesWritten += 1
        totalSessionsCompleted += 1
        if let frameId = item.frameId, let idx = frames.firstIndex(where: { $0.id == frameId }) {
            frames[idx].captionId = item.id
            touchProject(id: frames[idx].projectId)
        }
        recordActivity()
        evaluateAchievements()
    }

    func updateCaption(_ item: CaptionItem) {
        guard let index = captions.firstIndex(where: { $0.id == item.id }) else { return }
        captions[index] = item
        recordActivity()
    }

    func deleteCaption(id: UUID) {
        captions.removeAll { $0.id == id }
        for i in frames.indices where frames[i].captionId == id {
            frames[i].captionId = nil
        }
    }

    // MARK: - Themes (templates)

    func markThemeViewed(_ themeId: String) {
        if !viewedThemeIds.contains(themeId) {
            viewedThemeIds.append(themeId)
        }
        currentThemeId = CuratedThemes.all.firstIndex(where: { $0.id == themeId }) ?? currentThemeId
    }

    @discardableResult
    func toggleFavourite(themeId: String) -> Bool {
        if let index = favouriteThemes.firstIndex(of: themeId) {
            favouriteThemes.remove(at: index)
            recordActivity()
            evaluateAchievements()
            return false
        } else {
            favouriteThemes.append(themeId)
            favouritesCount += 1
            totalSessionsCompleted += 1
            recordActivity()
            evaluateAchievements()
            return true
        }
    }

    func isFavourite(_ themeId: String) -> Bool {
        favouriteThemes.contains(themeId)
    }

    func removeFavourite(themeId: String) {
        favouriteThemes.removeAll { $0 == themeId }
        recordActivity()
    }

    // MARK: - Projects

    var activeProjects: [StoryProject] {
        projects
            .filter { !$0.isArchived }
            .sorted { lhs, rhs in
                if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    var archivedProjects: [StoryProject] {
        projects.filter(\.isArchived).sorted { $0.updatedAt > $1.updatedAt }
    }

    var lastOpenedProject: StoryProject? {
        if let id = lastOpenedProjectID {
            return projects.first(where: { $0.id == id && !$0.isArchived })
        }
        return activeProjects.first
    }

    func project(id: UUID) -> StoryProject? {
        projects.first(where: { $0.id == id })
    }

    func frames(for projectId: UUID) -> [StoryFrame] {
        let ids = project(id: projectId)?.frameIds ?? []
        let map = Dictionary(uniqueKeysWithValues: frames.map { ($0.id, $0) })
        return ids.compactMap { map[$0] }
    }

    @discardableResult
    func createProject(
        name: String,
        notes: String = "",
        tags: [String] = [],
        templateId: String? = nil
    ) -> StoryProject {
        var project = StoryProject(name: name, notes: notes, tags: tags, templateId: templateId)
        projects.insert(project, at: 0)
        lastOpenedProjectID = project.id
        favouritesCount += 1
        totalSessionsCompleted += 1
        recordActivity()
        evaluateAchievements()

        if let templateId,
           let theme = CuratedThemes.all.first(where: { $0.id == templateId }) {
            let starter = StoryFrame(
                projectId: project.id,
                title: theme.name,
                icon: "🎬",
                durationSeconds: 4,
                tags: [theme.name],
                order: 0
            )
            appendFrame(starter, to: &project)
        }
        return project
    }

    func updateProject(_ project: StoryProject) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        var updated = project
        updated.updatedAt = Date()
        projects[index] = updated
        lastOpenedProjectID = updated.id
        recordActivity()
    }

    func deleteProject(id: UUID) {
        let frameIds = Set(project(id: id)?.frameIds ?? [])
        projects.removeAll { $0.id == id }
        frames.removeAll { frameIds.contains($0.id) }
        captions.removeAll { $0.projectId == id }
        if lastOpenedProjectID == id {
            lastOpenedProjectID = activeProjects.first?.id
        }
        recordActivity()
    }

    func togglePin(projectId: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[index].isPinned.toggle()
        projects[index].updatedAt = Date()
        FeedbackService.lightTap()
        recordActivity()
    }

    func toggleArchive(projectId: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[index].isArchived.toggle()
        projects[index].updatedAt = Date()
        if projects[index].isArchived, lastOpenedProjectID == projectId {
            lastOpenedProjectID = activeProjects.first?.id
        }
        recordActivity()
    }

    @discardableResult
    func duplicateProject(id: UUID) -> StoryProject? {
        guard let source = project(id: id) else { return nil }
        var copy = StoryProject(
            name: source.name + " Copy",
            notes: source.notes,
            tags: source.tags,
            preferredLayout: source.preferredLayout,
            templateId: source.templateId
        )
        projects.insert(copy, at: 0)
        let sourceFrames = frames(for: id)
        var idMap: [UUID: UUID] = [:]
        for frame in sourceFrames {
            let newId = UUID()
            idMap[frame.id] = newId
            var newFrame = frame
            newFrame.id = newId
            newFrame.projectId = copy.id
            newFrame.captionId = nil
            newFrame.nextFrameId = nil
            frames.append(newFrame)
            copy.frameIds.append(newId)
            favouritesCount += 1
            itemsAdded += 1
        }
        for i in frames.indices where frames[i].projectId == copy.id {
            if let oldNext = sourceFrames.first(where: { idMap[$0.id] == frames[i].id })?.nextFrameId,
               let mapped = idMap[oldNext] {
                frames[i].nextFrameId = mapped
            }
        }
        if let idx = projects.firstIndex(where: { $0.id == copy.id }) {
            projects[idx] = copy
        }
        lastOpenedProjectID = copy.id
        totalSessionsCompleted += 1
        recordActivity()
        evaluateAchievements()
        return copy
    }

    func openProject(_ id: UUID) {
        lastOpenedProjectID = id
        touchProject(id: id)
    }

    // MARK: - Frames / Storyboard

    func addFrame(to projectId: UUID, title: String, icon: String, durationSeconds: Int, tags: [String]) {
        guard var project = project(id: projectId) else { return }
        let frame = StoryFrame(
            projectId: projectId,
            title: title,
            icon: icon,
            durationSeconds: max(1, durationSeconds),
            tags: tags,
            order: project.frameIds.count
        )
        appendFrame(frame, to: &project)
        itemsAdded += 1
        entriesWritten += 1
        favouritesCount += 1
        totalSessionsCompleted += 1
        recordActivity()
        evaluateAchievements()
    }

    func updateFrame(_ frame: StoryFrame) {
        guard let index = frames.firstIndex(where: { $0.id == frame.id }) else { return }
        frames[index] = frame
        touchProject(id: frame.projectId)
        recordActivity()
    }

    func deleteFrame(id: UUID) {
        guard let frame = frames.first(where: { $0.id == id }) else { return }
        frames.removeAll { $0.id == id }
        if let captionId = frame.captionId {
            captions.removeAll { $0.id == captionId }
        }
        for i in frames.indices where frames[i].nextFrameId == id {
            frames[i].nextFrameId = nil
        }
        if let pIndex = projects.firstIndex(where: { $0.id == frame.projectId }) {
            projects[pIndex].frameIds.removeAll { $0 == id }
            projects[pIndex].updatedAt = Date()
            reindexFrames(projectId: frame.projectId)
        }
        recordActivity()
    }

    func linkFrames(from: UUID, to: UUID?) {
        guard let index = frames.firstIndex(where: { $0.id == from }) else { return }
        frames[index].nextFrameId = to
        touchProject(id: frames[index].projectId)
        recordActivity()
    }

    func setLayout(_ layout: StoryboardLayout, for projectId: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[index].preferredLayout = layout
        projects[index].updatedAt = Date()
    }

    func moveFrame(projectId: UUID, fromOffsets: IndexSet, toOffset: Int) {
        guard let pIndex = projects.firstIndex(where: { $0.id == projectId }) else { return }
        var ids = projects[pIndex].frameIds
        let moving = fromOffsets.sorted().map { ids[$0] }
        for index in fromOffsets.sorted(by: >) {
            ids.remove(at: index)
        }
        let destination = min(max(toOffset, 0), ids.count)
        ids.insert(contentsOf: moving, at: destination)
        projects[pIndex].frameIds = ids
        projects[pIndex].updatedAt = Date()
        reindexFrames(projectId: projectId)
        recordActivity()
    }

    func exportScript(for projectId: UUID) -> String {
        guard let project = project(id: projectId) else { return "" }
        let projectFrames = frames(for: projectId)
        var lines: [String] = [
            "STORYBOARD SCRIPT",
            "Project: \(project.name)",
            project.notes.isEmpty ? "" : "Notes: \(project.notes)",
            project.tags.isEmpty ? "" : "Tags: \(project.tags.joined(separator: ", "))",
            ""
        ]
        for (index, frame) in projectFrames.enumerated() {
            lines.append("Beat \(index + 1) — \(frame.title)")
            lines.append("Duration: \(frame.durationSeconds)s · Icon: \(frame.icon)")
            if !frame.tags.isEmpty {
                lines.append("Tags: \(frame.tags.joined(separator: ", "))")
            }
            if let next = frame.nextFrameId,
               let nextFrame = projectFrames.first(where: { $0.id == next }) {
                lines.append("Next beat → \(nextFrame.title)")
            }
            if let captionId = frame.captionId,
               let caption = captions.first(where: { $0.id == captionId }) {
                let role = caption.beatRole?.title ?? "Caption"
                lines.append("\(role): \(caption.text)")
                if !caption.variants.isEmpty {
                    lines.append("Variants:")
                    for (vIndex, variant) in caption.variants.enumerated() {
                        let mark = vIndex == caption.selectedVariantIndex ? "★" : "•"
                        lines.append("  \(mark) \(variant)")
                    }
                }
            } else {
                lines.append("Caption: (none)")
            }
            lines.append("")
        }
        let total = projectFrames.reduce(0) { $0 + $1.durationSeconds }
        lines.append("Total runtime: \(total)s across \(projectFrames.count) beats.")
        return lines.filter { !$0.isEmpty || true }.joined(separator: "\n")
    }

    // MARK: - Analytics

    var allTags: [String] {
        var tags: [String] = []
        tags.append(contentsOf: projects.flatMap(\.tags))
        tags.append(contentsOf: frames.flatMap(\.tags))
        tags.append(contentsOf: entries.map(\.title))
        return tags
    }

    func tagFrequencies() -> [TagFrequency] {
        var counts: [String: Int] = [:]
        for tag in allTags {
            let key = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { continue }
            counts[key, default: 0] += 1
        }
        return counts
            .map { TagFrequency(tag: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    func coOccurrences(limit: Int = 8) -> [TagCoOccurrence] {
        var pairCounts: [String: (String, String, Int)] = [:]
        let groups: [[String]] = projects.map(\.tags) + frames.map(\.tags)
        for group in groups {
            let unique = Array(Set(group.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })).sorted()
            guard unique.count >= 2 else { continue }
            for i in 0..<unique.count {
                for j in (i + 1)..<unique.count {
                    let key = unique[i] + "|" + unique[j]
                    let existing = pairCounts[key]?.2 ?? 0
                    pairCounts[key] = (unique[i], unique[j], existing + 1)
                }
            }
        }
        return pairCounts.values
            .map { TagCoOccurrence(left: $0.0, right: $0.1, count: $0.2) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }

    func topMotifInsight() -> String {
        let frequencies = tagFrequencies()
        guard let top = frequencies.first else {
            return "Add tagged frames to reveal your leading motif."
        }
        let month = Calendar.current.component(.month, from: Date())
        let monthName = DateFormatter().monthSymbols[month - 1]
        return "This month your top motif is \(top.tag) (\(top.count)× across \(monthName))."
    }

    func weeklyReviewLines() -> [String] {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
              let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now) else {
            return ["Not enough data for a weekly review yet."]
        }

        let recentFrames = frames.filter { $0.createdAt >= weekAgo }
        let previousFrames = frames.filter { $0.createdAt >= twoWeeksAgo && $0.createdAt < weekAgo }
        let recentCaptions = captions.filter { $0.timestamp >= weekAgo }
        let recentProjects = projects.filter { $0.updatedAt >= weekAgo && !$0.isArchived }

        var recentCounts: [String: Int] = [:]
        for tag in recentFrames.flatMap(\.tags) {
            recentCounts[tag, default: 0] += 1
        }
        var previousCounts: [String: Int] = [:]
        for tag in previousFrames.flatMap(\.tags) {
            previousCounts[tag, default: 0] += 1
        }

        let growing = recentCounts
            .map { (tag: $0.key, delta: $0.value - (previousCounts[$0.key] ?? 0)) }
            .filter { $0.delta > 0 }
            .sorted { $0.delta > $1.delta }

        var lines: [String] = []
        lines.append("Last 7 days: \(recentProjects.count) projects touched, \(recentFrames.count) frames, \(recentCaptions.count) captions.")
        lines.append("Organizing streak: \(streakDays) day\(streakDays == 1 ? "" : "s").")
        if let top = growing.first {
            lines.append("Rising theme: \(top.tag) (+\(top.delta) vs prior week).")
        } else if let top = recentCounts.max(by: { $0.value < $1.value }) {
            lines.append("Most used theme: \(top.key) (\(top.value)×).")
        } else {
            lines.append("No rising themes yet — tag a few frames this week.")
        }
        let unfinished = frames.filter { $0.needsCaption && !$0.isUntagged }.count
        if unfinished > 0 {
            lines.append("\(unfinished) tagged frame\(unfinished == 1 ? "" : "s") still need captions.")
        }
        return lines
    }

    func smartStackCount(_ kind: SmartStackKind) -> Int {
        smartStackFrames(kind).count
    }

    func smartStackFrames(_ kind: SmartStackKind) -> [StoryFrame] {
        switch kind {
        case .untagged:
            return frames.filter(\.isUntagged)
        case .needsCaption:
            return frames.filter(\.needsCaption)
        case .rareThemes:
            let frequencies = Dictionary(uniqueKeysWithValues: tagFrequencies().map { ($0.tag, $0.count) })
            return frames.filter { frame in
                guard !frame.tags.isEmpty else { return false }
                return frame.tags.contains { (frequencies[$0] ?? 0) <= 2 }
            }
        case .unfinished:
            return frames.filter { $0.needsCaption || $0.isUntagged }
        }
    }

    func searchFrames(query: String, tag: String?, projectId: UUID?, from: Date?, to: Date?) -> [StoryFrame] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return frames.filter { frame in
            if let projectId, frame.projectId != projectId { return false }
            if let tag, !tag.isEmpty, !frame.tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
                return false
            }
            if let from, frame.createdAt < from { return false }
            if let to, frame.createdAt > to { return false }
            if q.isEmpty { return true }
            let hay = ([frame.title] + frame.tags).joined(separator: " ").lowercased()
            return hay.contains(q)
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    func dailyPrompt() -> String {
        DailyPromptPool.prompt()
    }

    // MARK: - Time / reset / achievements

    func tickActiveTime(now: Date = Date()) {
        if let last = lastMinuteTick {
            minuteAccumulator += now.timeIntervalSince(last)
            if minuteAccumulator >= 60 {
                let minutes = Int(minuteAccumulator / 60)
                totalMinutesUsed += minutes
                minuteAccumulator -= TimeInterval(minutes * 60)
            }
        }
        lastMinuteTick = now
    }

    func pauseActiveTimeTracking() {
        lastMinuteTick = nil
    }

    func resetAllData() {
        let domain = Bundle.main.bundleIdentifier ?? ""
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
        reloadFromDefaults()
        pendingAchievementIDs = []
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    func isAchievementUnlocked(_ id: AchievementID) -> Bool {
        achievementsUnlocked[id.rawValue] != nil
    }

    // MARK: - Private helpers

    private func appendFrame(_ frame: StoryFrame, to project: inout StoryProject) {
        frames.append(frame)
        project.frameIds.append(frame.id)
        project.updatedAt = Date()
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        } else {
            projects.insert(project, at: 0)
        }
        lastOpenedProjectID = project.id
        linkSequentialBeats(projectId: project.id)
    }

    private func linkSequentialBeats(projectId: UUID) {
        let ordered = frames(for: projectId)
        guard ordered.count >= 2 else { return }
        for i in 0..<(ordered.count - 1) {
            if let idx = frames.firstIndex(where: { $0.id == ordered[i].id }) {
                frames[idx].nextFrameId = ordered[i + 1].id
            }
        }
    }

    private func reindexFrames(projectId: UUID) {
        let orderedIds = project(id: projectId)?.frameIds ?? []
        for (order, id) in orderedIds.enumerated() {
            if let idx = frames.firstIndex(where: { $0.id == id }) {
                frames[idx].order = order
            }
        }
        linkSequentialBeats(projectId: projectId)
    }

    private func touchProject(id: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == id }) else { return }
        projects[index].updatedAt = Date()
        lastOpenedProjectID = id
    }

    private func recordActivity() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let last = lastActivityDate {
            let lastDay = calendar.startOfDay(for: last)
            if lastDay == today {
                return
            }
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), lastDay == yesterday {
                streakDays += 1
            } else {
                streakDays = 1
            }
        } else {
            streakDays = 1
        }
        lastActivityDate = Date()
    }

    private func evaluateAchievements() {
        check(.firstSteps, condition: itemsAdded >= 1)
        check(.explorer, condition: itemsAdded >= 5)
        check(.curator, condition: entriesWritten >= 10)
        check(.collectionBuilder, condition: favouritesCount >= 20)
        check(.gettingGoing, condition: itemsAdded >= 10)
        check(.powerUser, condition: itemsAdded >= 50)
        check(.dedicatedUser, condition: entriesWritten >= 50)
        check(.threeDayStreak, condition: streakDays >= 3)
    }

    private func check(_ id: AchievementID, condition: Bool) {
        guard condition, achievementsUnlocked[id.rawValue] == nil else { return }
        achievementsUnlocked[id.rawValue] = Date()
        pendingAchievementIDs.append(id.rawValue)
        NotificationCenter.default.post(name: .achievementUnlocked, object: id.rawValue)
        FeedbackService.achievementUnlocked()
    }

    private func reloadFromDefaults() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        totalSessionsCompleted = defaults.integer(forKey: Keys.totalSessionsCompleted)
        totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        streakDays = defaults.integer(forKey: Keys.streakDays)
        lastActivityDate = defaults.object(forKey: Keys.lastActivityDate) as? Date
        achievementsUnlocked = Self.loadCodable([String: Date].self, key: Keys.achievementsUnlocked) ?? [:]
        let loadedEntries = Self.loadCodable([TagEntry].self, key: Keys.entries) ?? []
        entryCount = defaults.object(forKey: Keys.entryCount) as? Int ?? loadedEntries.count
        entries = loadedEntries
        if let idString = defaults.string(forKey: Keys.lastViewedEntryID) {
            lastViewedEntryID = UUID(uuidString: idString)
        } else {
            lastViewedEntryID = nil
        }
        itemsAdded = defaults.integer(forKey: Keys.itemsAdded)
        entriesWritten = defaults.integer(forKey: Keys.entriesWritten)
        favouritesCount = defaults.integer(forKey: Keys.favouritesCount)
        captions = Self.loadCodable([CaptionItem].self, key: Keys.captions) ?? []
        currentThemeId = defaults.integer(forKey: Keys.currentThemeId)
        favouriteThemes = defaults.stringArray(forKey: Keys.favouriteThemes) ?? []
        viewedThemeIds = defaults.stringArray(forKey: Keys.viewedThemeIds) ?? []
        projects = Self.loadCodable([StoryProject].self, key: Keys.projects) ?? []
        frames = Self.loadCodable([StoryFrame].self, key: Keys.frames) ?? []
        if let projectString = defaults.string(forKey: Keys.lastOpenedProjectID) {
            lastOpenedProjectID = UUID(uuidString: projectString)
        } else {
            lastOpenedProjectID = nil
        }
        selectedInsightTag = defaults.string(forKey: Keys.selectedInsightTag)
        minuteAccumulator = 0
        lastMinuteTick = nil
    }

    private func saveCodable<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func loadCodable<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
