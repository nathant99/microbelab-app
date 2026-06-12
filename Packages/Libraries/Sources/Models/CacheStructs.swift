import Foundation

/// Value-type cache structs for the @Model types.
///
/// Per `.claude/rules/swiftdata.md` § Data Access — never pass `@Model` objects
/// to views and never traverse `@Relationship` in `body`. Cache to these
/// lightweight, display-only structs in `onAppear` and feed them to views.
///
/// All structs here are `nonisolated public` Sendable value types so they
/// move freely across MainActor boundaries.

public nonisolated struct PlayerProgressData: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let displayName: String
    public let totalXP: Int
    public let currentStreak: Int
    public let longestStreak: Int
    public let lastActiveDate: Date?
    public let discoveredMicrobeIDs: Set<UUID>
    public let earnedAchievementSlugs: Set<String>

    public init(
        id: UUID,
        displayName: String,
        totalXP: Int,
        currentStreak: Int,
        longestStreak: Int,
        lastActiveDate: Date?,
        discoveredMicrobeIDs: Set<UUID>,
        earnedAchievementSlugs: Set<String>
    ) {
        self.id = id
        self.displayName = displayName
        self.totalXP = totalXP
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActiveDate = lastActiveDate
        self.discoveredMicrobeIDs = discoveredMicrobeIDs
        self.earnedAchievementSlugs = earnedAchievementSlugs
    }

    public init(from progress: PlayerProgress) {
        self.init(
            id: progress.id,
            displayName: progress.displayName,
            totalXP: progress.totalXP,
            currentStreak: progress.currentStreak,
            longestStreak: progress.longestStreak,
            lastActiveDate: progress.lastActiveDate,
            discoveredMicrobeIDs: progress.discoveredMicrobeIDs,
            earnedAchievementSlugs: progress.earnedAchievementSlugs
        )
    }
}

public nonisolated struct EncounterLogData: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let microbeID: UUID
    public let slug: String
    public let encounteredAt: Date
    public let atZoomTier: ZoomTier
    public let inSlot: GutSlot
    public let sessionID: UUID?

    public init(
        id: UUID,
        microbeID: UUID,
        slug: String,
        encounteredAt: Date,
        atZoomTier: ZoomTier,
        inSlot: GutSlot,
        sessionID: UUID?
    ) {
        self.id = id
        self.microbeID = microbeID
        self.slug = slug
        self.encounteredAt = encounteredAt
        self.atZoomTier = atZoomTier
        self.inSlot = inSlot
        self.sessionID = sessionID
    }

    public init(from log: EncounterLog) {
        self.init(
            id: log.id,
            microbeID: log.microbeID,
            slug: log.slug,
            encounteredAt: log.encounteredAt,
            atZoomTier: log.atZoomTier,
            inSlot: GutSlot(rawValue: log.inSlot) ?? .colon,
            sessionID: log.sessionID
        )
    }
}

public nonisolated struct JournalEntryData: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let createdAt: Date
    public let body: String
    public let relatedMicrobeID: UUID?
    public let promptSlug: String?

    public init(
        id: UUID,
        createdAt: Date,
        body: String,
        relatedMicrobeID: UUID?,
        promptSlug: String?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.body = body
        self.relatedMicrobeID = relatedMicrobeID
        self.promptSlug = promptSlug
    }

    public init(from entry: JournalEntry) {
        self.init(
            id: entry.id,
            createdAt: entry.createdAt,
            body: entry.body,
            relatedMicrobeID: entry.relatedMicrobeID,
            promptSlug: entry.promptSlug
        )
    }
}

public nonisolated struct MicrobeSessionData: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let startedAt: Date
    public let endedAt: Date?
    public let highestZoomTier: ZoomTier
    public let finalState: MicrobiomeState?

    public init(
        id: UUID,
        startedAt: Date,
        endedAt: Date?,
        highestZoomTier: ZoomTier,
        finalState: MicrobiomeState?
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.highestZoomTier = highestZoomTier
        self.finalState = finalState
    }

    public init(from session: PersistentMicrobeSession) {
        self.init(
            id: session.id,
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            highestZoomTier: session.highestZoomTier,
            finalState: session.decodedState()
        )
    }
}
