import Foundation

// MARK: - Core story models

struct StoryProject: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var notes: String
    var tags: [String]
    var isPinned: Bool
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date
    var frameIds: [UUID]
    var preferredLayout: StoryboardLayout
    var templateId: String?

    init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        tags: [String] = [],
        isPinned: Bool = false,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        frameIds: [UUID] = [],
        preferredLayout: StoryboardLayout = .filmstrip,
        templateId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.tags = tags
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.frameIds = frameIds
        self.preferredLayout = preferredLayout
        self.templateId = templateId
    }
}

enum StoryboardLayout: String, Codable, CaseIterable, Identifiable {
    case grid2x2
    case filmstrip
    case vertical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grid2x2: return "2×2"
        case .filmstrip: return "Filmstrip"
        case .vertical: return "Vertical"
        }
    }
}

struct StoryFrame: Identifiable, Codable, Equatable {
    var id: UUID
    var projectId: UUID
    var title: String
    var icon: String
    var durationSeconds: Int
    var nextFrameId: UUID?
    var captionId: UUID?
    var tags: [String]
    var order: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID,
        title: String,
        icon: String = "🎬",
        durationSeconds: Int = 4,
        nextFrameId: UUID? = nil,
        captionId: UUID? = nil,
        tags: [String] = [],
        order: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.icon = icon
        self.durationSeconds = durationSeconds
        self.nextFrameId = nextFrameId
        self.captionId = captionId
        self.tags = tags
        self.order = order
        self.createdAt = createdAt
    }

    var needsCaption: Bool { captionId == nil }
    var isUntagged: Bool { tags.isEmpty }
}

struct CaptionEditRecord: Codable, Equatable {
    var text: String
    var timestamp: Date
}

enum CaptionBeatRole: String, Codable, CaseIterable, Identifiable {
    case setup
    case conflict
    case detail
    case close

    var id: String { rawValue }

    var title: String {
        switch self {
        case .setup: return "Setup"
        case .conflict: return "Conflict"
        case .detail: return "Detail"
        case .close: return "Close"
        }
    }

    var promptHint: String {
        switch self {
        case .setup: return "Set the place, time, and who is present."
        case .conflict: return "Name the tension or turning point."
        case .detail: return "Zoom into a concrete sensory detail."
        case .close: return "Land the feeling or lesson of the beat."
        }
    }
}

enum CaptionTone: String, Codable, CaseIterable, Identifiable {
    case warm
    case sparse
    case documentary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .warm: return "Warm"
        case .sparse: return "Sparse"
        case .documentary: return "Documentary"
        }
    }
}

struct TagEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var icon: String

    init(id: UUID = UUID(), title: String, icon: String) {
        self.id = id
        self.title = title
        self.icon = icon
    }
}

struct CaptionItem: Identifiable, Codable, Equatable {
    var id: UUID
    var text: String
    var timestamp: Date
    var symbolName: String
    var projectId: UUID?
    var frameId: UUID?
    var beatRole: CaptionBeatRole?
    var tone: CaptionTone?
    var variants: [String]
    var selectedVariantIndex: Int
    var editHistory: [CaptionEditRecord]

    init(
        id: UUID = UUID(),
        text: String,
        timestamp: Date = Date(),
        symbolName: String = "photo",
        projectId: UUID? = nil,
        frameId: UUID? = nil,
        beatRole: CaptionBeatRole? = nil,
        tone: CaptionTone? = nil,
        variants: [String] = [],
        selectedVariantIndex: Int = 0,
        editHistory: [CaptionEditRecord] = []
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.symbolName = symbolName
        self.projectId = projectId
        self.frameId = frameId
        self.beatRole = beatRole
        self.tone = tone
        self.variants = variants
        self.selectedVariantIndex = selectedVariantIndex
        self.editHistory = editHistory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        symbolName = try container.decodeIfPresent(String.self, forKey: .symbolName) ?? "photo"
        projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        frameId = try container.decodeIfPresent(UUID.self, forKey: .frameId)
        beatRole = try container.decodeIfPresent(CaptionBeatRole.self, forKey: .beatRole)
        tone = try container.decodeIfPresent(CaptionTone.self, forKey: .tone)
        variants = try container.decodeIfPresent([String].self, forKey: .variants) ?? []
        selectedVariantIndex = try container.decodeIfPresent(Int.self, forKey: .selectedVariantIndex) ?? 0
        editHistory = try container.decodeIfPresent([CaptionEditRecord].self, forKey: .editHistory) ?? []
    }
}

struct ThemeCollection: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let symbolName: String
    let accentIndex: Int
}

enum SmartStackKind: String, CaseIterable, Identifiable {
    case untagged
    case needsCaption
    case rareThemes
    case unfinished

    var id: String { rawValue }

    var title: String {
        switch self {
        case .untagged: return "Untagged"
        case .needsCaption: return "Needs Caption"
        case .rareThemes: return "Rare Themes"
        case .unfinished: return "Unfinished"
        }
    }

    var subtitle: String {
        switch self {
        case .untagged: return "Beats missing tags"
        case .needsCaption: return "Waiting for copy"
        case .rareThemes: return "Seldom used tags"
        case .unfinished: return "Open story gaps"
        }
    }

    var symbolName: String {
        switch self {
        case .untagged: return "tag.slash"
        case .needsCaption: return "text.badge.plus"
        case .rareThemes: return "magnifyingglass"
        case .unfinished: return "circle.dashed"
        }
    }
}

struct TagFrequency: Identifiable {
    var id: String { tag }
    let tag: String
    let count: Int
}

struct TagCoOccurrence: Identifiable {
    var id: String { "\(left)|\(right)" }
    let left: String
    let right: String
    let count: Int
}

enum AchievementID: String, CaseIterable, Codable {
    case firstSteps
    case explorer
    case curator
    case collectionBuilder
    case gettingGoing
    case powerUser
    case dedicatedUser
    case threeDayStreak

    var title: String {
        switch self {
        case .firstSteps: return "First Steps"
        case .explorer: return "Explorer"
        case .curator: return "Curator"
        case .collectionBuilder: return "Collection Builder"
        case .gettingGoing: return "Getting Going"
        case .powerUser: return "Power User"
        case .dedicatedUser: return "Dedicated User"
        case .threeDayStreak: return "Three-Day Streak"
        }
    }

    var detail: String {
        switch self {
        case .firstSteps: return "Tagged your first image."
        case .explorer: return "Created five tagged images."
        case .curator: return "Added ten entries to storyboards."
        case .collectionBuilder: return "Organized twenty images into collections."
        case .gettingGoing: return "Reached 10 items."
        case .powerUser: return "Reached 50 items."
        case .dedicatedUser: return "Completed 50 sessions."
        case .threeDayStreak: return "Used the app 3 days in a row."
        }
    }

    var symbolName: String {
        switch self {
        case .firstSteps: return "flag.fill"
        case .explorer: return "binoculars.fill"
        case .curator: return "rectangle.stack.fill"
        case .collectionBuilder: return "square.grid.2x2.fill"
        case .gettingGoing: return "bolt.fill"
        case .powerUser: return "flame.fill"
        case .dedicatedUser: return "star.fill"
        case .threeDayStreak: return "calendar"
        }
    }
}

enum TagIconOption {
    static let all: [String] = [
        "⭐️", "🎬", "📷", "🌙", "☀️", "🎵", "🏔", "🌊",
        "🌸", "☕", "📖", "✈️", "🏠", "💡", "🎯", "🌈"
    ]
}

enum CaptionSymbolOption {
    static let all: [String] = [
        "photo", "camera", "film", "book", "leaf", "moon.stars",
        "sun.max", "cloud", "heart", "star", "bookmark", "tag"
    ]
}

enum DailyPromptPool {
    static let prompts: [String] = [
        "Describe the quietest detail in this beat.",
        "What changed between the first and last frame?",
        "Write the caption as if spoken to a close friend.",
        "Name the color that carries the mood.",
        "What would you leave out to make this sharper?",
        "Caption the moment before the peak.",
        "Find one concrete object and let it lead the line.",
        "Write three words, then expand only one.",
        "Where does the story breathe?",
        "What feeling arrives last?",
        "Caption the transition, not the destination.",
        "If this beat had a weather, what is it?",
        "Who is missing from the frame, and why does it matter?",
        "Reduce the caption to one honest sentence.",
        "What detail would only you notice?"
    ]

    static func prompt(for date: Date = Date()) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return prompts[day % prompts.count]
    }
}

enum CuratedThemes {
    static let all: [ThemeCollection] = [
        ThemeCollection(id: "golden_hour", name: "Golden Hour", description: "Warm light moments for reflective storyboards.", symbolName: "sun.horizon", accentIndex: 0),
        ThemeCollection(id: "city_nights", name: "City Nights", description: "Urban evenings and glowing streets.", symbolName: "building.2", accentIndex: 1),
        ThemeCollection(id: "quiet_mornings", name: "Quiet Mornings", description: "Soft starts and calm routines.", symbolName: "cup.and.saucer", accentIndex: 2),
        ThemeCollection(id: "coastal_walks", name: "Coastal Walks", description: "Shorelines, breeze, and open horizons.", symbolName: "water.waves", accentIndex: 3),
        ThemeCollection(id: "forest_paths", name: "Forest Paths", description: "Green trails and shaded stillness.", symbolName: "leaf", accentIndex: 4),
        ThemeCollection(id: "studio_moods", name: "Studio Moods", description: "Creative desks and focused frames.", symbolName: "paintpalette", accentIndex: 5),
        ThemeCollection(id: "weekend_tables", name: "Weekend Tables", description: "Shared meals and slow conversations.", symbolName: "fork.knife", accentIndex: 0),
        ThemeCollection(id: "travel_notes", name: "Travel Notes", description: "Journeys captured as visual chapters.", symbolName: "airplane", accentIndex: 1),
        ThemeCollection(id: "rainy_windows", name: "Rainy Windows", description: "Soft weather and indoor comfort.", symbolName: "cloud.rain", accentIndex: 2),
        ThemeCollection(id: "night_sky", name: "Night Sky", description: "Stars, silence, and deep blues.", symbolName: "moon.stars", accentIndex: 3),
        ThemeCollection(id: "garden_days", name: "Garden Days", description: "Blooms, soil, and seasonal color.", symbolName: "camera.macro", accentIndex: 4),
        ThemeCollection(id: "music_nights", name: "Music Nights", description: "Live sets and headphone stories.", symbolName: "music.note", accentIndex: 5),
        ThemeCollection(id: "bookshelf", name: "Bookshelf", description: "Pages, covers, and quiet corners.", symbolName: "books.vertical", accentIndex: 0),
        ThemeCollection(id: "kitchen_light", name: "Kitchen Light", description: "Everyday rituals in warm tones.", symbolName: "lightbulb", accentIndex: 1),
        ThemeCollection(id: "road_trips", name: "Road Trips", description: "Highways, maps, and roadside pauses.", symbolName: "car", accentIndex: 2),
        ThemeCollection(id: "winter_frames", name: "Winter Frames", description: "Cool air and crisp compositions.", symbolName: "snowflake", accentIndex: 3),
        ThemeCollection(id: "spring_reset", name: "Spring Reset", description: "Fresh starts and bright accents.", symbolName: "sparkles", accentIndex: 4),
        ThemeCollection(id: "summer_reels", name: "Summer Reels", description: "Long days and vibrant sequences.", symbolName: "sun.max", accentIndex: 5),
        ThemeCollection(id: "autumn_layers", name: "Autumn Layers", description: "Texture, tone, and fading light.", symbolName: "wind", accentIndex: 0),
        ThemeCollection(id: "portrait_soft", name: "Portrait Soft", description: "Faces, gesture, and gentle focus.", symbolName: "person.crop.circle", accentIndex: 1),
        ThemeCollection(id: "abstract_shapes", name: "Abstract Shapes", description: "Form, color blocks, and pattern play.", symbolName: "square.on.circle", accentIndex: 2),
        ThemeCollection(id: "home_corners", name: "Home Corners", description: "Familiar spaces made intentional.", symbolName: "house", accentIndex: 3),
        ThemeCollection(id: "festival_glow", name: "Festival Glow", description: "Crowds, color, and shared energy.", symbolName: "sparkles", accentIndex: 4),
        ThemeCollection(id: "silent_rooms", name: "Silent Rooms", description: "Empty chairs and quiet geometry.", symbolName: "bed.double", accentIndex: 5)
    ]
}

enum CaptionVariantFactory {
    static func makeVariants(base: String, beat: CaptionBeatRole?, tone: CaptionTone?) -> [String] {
        let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        let seed = trimmed.isEmpty ? (beat?.promptHint ?? "A quiet beat in the story.") : trimmed
        let tonePrefix: String
        switch tone {
        case .warm: tonePrefix = "Softly: "
        case .sparse: tonePrefix = ""
        case .documentary: tonePrefix = "Observed: "
        case .none: tonePrefix = ""
        }
        let roleNote: String
        switch beat {
        case .setup: roleNote = " The scene opens here."
        case .conflict: roleNote = " Something shifts."
        case .detail: roleNote = " One detail holds."
        case .close: roleNote = " The beat settles."
        case .none: roleNote = ""
        }
        return [
            tonePrefix + seed,
            seed + roleNote,
            sparseLine(from: seed)
        ]
    }

    private static func sparseLine(from text: String) -> String {
        let words = text.split(separator: " ").prefix(6)
        if words.isEmpty { return "Still frame." }
        return words.joined(separator: " ")
    }
}
