import Foundation

/// Microbe kingdom (NGSS MS-LS1-1 baseline taxonomy).
public nonisolated enum MicrobeKingdom: String, Codable, Sendable, CaseIterable {
    case bacteria
    case archaea
    case fungi
    case virus
    case protist
}

/// Ecological / health role. Beneficial-first framing per CLAUDE.md
/// trauma-informed posture — pathogens are gated to kit 5+ with off-ramps.
public nonisolated enum MicrobeRole: String, Codable, Sendable, CaseIterable {
    case beneficial
    case neutral
    case opportunistic
    case pathogenic
}

/// Ecology zone the microbe prefers. Used by the microbiome simulator to
/// decide which microbes thrive in which gut-slot under given feeding modes.
public nonisolated enum GutSlot: String, Codable, Sendable, CaseIterable {
    case oralCavity
    case stomach
    case smallIntestine
    case largeIntestine
    case colon
    case skin
    case soil
}

/// Per-tick growth modifiers under each feeding mode. Range roughly -1.0 ... +1.0.
public nonisolated struct GrowthRate: Codable, Sendable, Equatable {
    public let onFiber: Double
    public let onSugar: Double
    public let onBalanced: Double
    public let onNone: Double

    public init(onFiber: Double, onSugar: Double, onBalanced: Double, onNone: Double) {
        self.onFiber = onFiber
        self.onSugar = onSugar
        self.onBalanced = onBalanced
        self.onNone = onNone
    }

    public func modifier(for mode: FeedingMode) -> Double {
        switch mode {
        case .fiber: return onFiber
        case .sugar: return onSugar
        case .balanced: return onBalanced
        case .none: return onNone
        }
    }
}

/// Named microbe character. The cast IS the curriculum — see
/// `Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md`.
public nonisolated struct MicrobeCharacter: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let slug: String
    public let displayName: String
    public let kingdom: MicrobeKingdom
    public let role: MicrobeRole
    public let preferredEnvironment: GutSlot
    public let growthRate: GrowthRate
    /// Catchphrase per DN voice-register card. Surfaced when the character first
    /// appears in the codex or at zoom-tier transitions.
    public let catchphrase: String
    /// Brief curriculum-mapped fact. Authored content only — never AI-generated
    /// per `.claude/rules/ai-content.md`.
    public let factCard: String
    /// Kit number at which this character is first introduced (1-indexed).
    public let firstKit: Int
    /// 3-5 in-character voice lines per the DN-S voice-register card. Decoded
    /// with a default so older JSON catalogs without the field still parse.
    public let voiceLines: [String]

    public init(
        id: UUID,
        slug: String,
        displayName: String,
        kingdom: MicrobeKingdom,
        role: MicrobeRole,
        preferredEnvironment: GutSlot,
        growthRate: GrowthRate,
        catchphrase: String,
        factCard: String,
        firstKit: Int,
        voiceLines: [String] = []
    ) {
        self.id = id
        self.slug = slug
        self.displayName = displayName
        self.kingdom = kingdom
        self.role = role
        self.preferredEnvironment = preferredEnvironment
        self.growthRate = growthRate
        self.catchphrase = catchphrase
        self.factCard = factCard
        self.firstKit = firstKit
        self.voiceLines = voiceLines
    }

    private enum CodingKeys: String, CodingKey {
        case id, slug, displayName, kingdom, role, preferredEnvironment
        case growthRate, catchphrase, factCard, firstKit, voiceLines
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.slug = try container.decode(String.self, forKey: .slug)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.kingdom = try container.decode(MicrobeKingdom.self, forKey: .kingdom)
        self.role = try container.decode(MicrobeRole.self, forKey: .role)
        self.preferredEnvironment = try container.decode(GutSlot.self, forKey: .preferredEnvironment)
        self.growthRate = try container.decode(GrowthRate.self, forKey: .growthRate)
        self.catchphrase = try container.decode(String.self, forKey: .catchphrase)
        self.factCard = try container.decode(String.self, forKey: .factCard)
        self.firstKit = try container.decode(Int.self, forKey: .firstKit)
        self.voiceLines = (try? container.decode([String].self, forKey: .voiceLines)) ?? []
    }
}
