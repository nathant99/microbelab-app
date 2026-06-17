import Foundation
import Observation
import ForgeGamification
import ForgeModels

/// Phase-1 achievement set per `Docs/FEATURE_PLAN.md` § Gamification.
/// Static definitions — content lives here so the implementing session can
/// register them with `AchievementEngine` without round-tripping through
/// labsmith.
public nonisolated enum MicrobeLabAchievements {
    public static let firstZoom = AchievementDefinition(
        id: "ml.first-zoom",
        title: "First Zoom",
        description: "You snapped the microscope to a real magnification tier for the first time.",
        iconAssetName: "scope",
        xpValue: 25
    )
    public static let firstMicrobe = AchievementDefinition(
        id: "ml.first-microbe",
        title: "First Friend",
        description: "You met your first microbe character.",
        iconAssetName: "person.crop.circle.badge.checkmark",
        xpValue: 50
    )
    public static let fiberPioneer = AchievementDefinition(
        id: "ml.fiber-pioneer",
        title: "Fiber Pioneer",
        description: "You fed the microbiome a fiber-rich meal.",
        iconAssetName: "leaf",
        xpValue: 30
    )
    public static let sugarTrial = AchievementDefinition(
        id: "ml.sugar-trial",
        title: "Sugar Trial",
        description: "You watched what happens when sugar comes to town.",
        iconAssetName: "drop",
        xpValue: 30
    )
    public static let firstQuiz = AchievementDefinition(
        id: "ml.first-quiz",
        title: "First Kit Cleared",
        description: "You finished a question kit.",
        iconAssetName: "checkmark.seal",
        xpValue: 60
    )
    public static let quizPerfect = AchievementDefinition(
        id: "ml.quiz-perfect",
        title: "Perfect Kit",
        description: "You got every question right.",
        iconAssetName: "star.fill",
        xpValue: 80
    )
    public static let immuneRookie = AchievementDefinition(
        id: "ml.immune-rookie",
        title: "Immune Rookie",
        description: "You cleared the first wave of the defense game.",
        iconAssetName: "shield",
        xpValue: 40
    )
    public static let immuneRunner = AchievementDefinition(
        id: "ml.immune-runner",
        title: "Immune Runner",
        description: "You cleared every wave of the Phase 1 defense game.",
        iconAssetName: "shield.lefthalf.filled",
        xpValue: 120
    )
    public static let microbiomeSteady = AchievementDefinition(
        id: "ml.microbiome-steady",
        title: "Steady Ecology",
        description: "You kept the microbiome stable for 10 ticks.",
        iconAssetName: "circle.grid.3x3",
        xpValue: 70
    )
    public static let codexHalf = AchievementDefinition(
        id: "ml.codex-half",
        title: "Half the Codex",
        description: "You discovered six microbes.",
        iconAssetName: "book.closed.fill",
        xpValue: 100
    )

    public static let phase1: [AchievementDefinition] = [
        firstZoom, firstMicrobe, fiberPioneer, sugarTrial,
        firstQuiz, quizPerfect, immuneRookie, immuneRunner,
        microbiomeSteady, codexHalf,
    ]

    // MARK: - Phase 2 (Adaptive Immunity + Microbiome Expansion)

    public static let firstShapeMatch = AchievementDefinition(
        id: "ml.first-shape-match",
        title: "First Shape Match",
        description: "You recognized your first antigen shape with the B-cell library.",
        iconAssetName: "puzzlepiece",
        xpValue: 40
    )
    public static let memoryAwakened = AchievementDefinition(
        id: "ml.memory-awakened",
        title: "Memory Awakened",
        description: "You matched a shape the body had recognized before — memory cells in action.",
        iconAssetName: "brain",
        xpValue: 60
    )
    public static let adaptiveRookie = AchievementDefinition(
        id: "ml.adaptive-rookie",
        title: "Adaptive Rookie",
        description: "You cleared your first wave on the adaptive surface.",
        iconAssetName: "puzzlepiece.fill",
        xpValue: 50
    )
    public static let adaptiveRunner = AchievementDefinition(
        id: "ml.adaptive-runner",
        title: "Adaptive Runner",
        description: "You filled the B-cell library all the way through every wave.",
        iconAssetName: "books.vertical.fill",
        xpValue: 140
    )
    public static let librarianOfShapes = AchievementDefinition(
        id: "ml.librarian-of-shapes",
        title: "Librarian of Shapes",
        description: "Every shape the body knows lives in your library — all four memory cells recorded.",
        iconAssetName: "square.stack.3d.up.fill",
        xpValue: 100
    )

    // Per-ecology balance-keeper achievements (oral / skin / soil). Each
    // rewards the kid for holding a per-ecology microbiome stable under the
    // ecology's gentle-care equivalent of fiber feeding. Trauma-informed
    // posture inherited from kits 06/07/08: ecology is a neighborhood, never
    // a battlefield; the achievement names recognition + care, not victory.
    public static let oralBalanceKeeper = AchievementDefinition(
        id: "ml.oral-balance-keeper",
        title: "Mouthful Steadier",
        description: "You kept the oral neighborhood steady — water, fruit, and gentle brushing held the balance.",
        iconAssetName: "mouth.fill",
        xpValue: 80
    )
    public static let skinKindnessChampion = AchievementDefinition(
        id: "ml.skin-kindness-champion",
        title: "Skin Garden Tender",
        description: "You cared for the skin garden — gentle washing kept the community in balance.",
        iconAssetName: "hand.raised.fill",
        xpValue: 80
    )
    public static let soilDecomposerWhisperer = AchievementDefinition(
        id: "ml.soil-decomposer-whisperer",
        title: "Underground Steward",
        description: "You held the soil neighborhood steady — decomposers, nitrogen-fixers, and extremophiles all thriving.",
        iconAssetName: "leaf.arrow.triangle.circlepath",
        xpValue: 100
    )

    public static let phase2: [AchievementDefinition] = [
        firstShapeMatch, memoryAwakened, adaptiveRookie,
        adaptiveRunner, librarianOfShapes,
        oralBalanceKeeper, skinKindnessChampion, soilDecomposerWhisperer,
    ]

    // MARK: - Phase 3 (Disease Stories + Vaccines)
    //
    // 4 disease-themed achievements pair 1:1 with the 4 Phase 3 disease-story
    // arcs scaffolded in PR #141 (`Models/DiseaseStoryArc`). Per
    // .claude/rules/trauma-informed-content.md the arcs themselves are
    // reviewer-gated; the achievements share the same SAMHSA-register
    // posture — names recognize care + curiosity + stewardship, never
    // victory / failure-recovery / threat-resolution framing.
    //
    // Title + description copy intentionally avoids: warfare lexicon
    // (`fight` / `attack` / `defeat` / `battle` / `weapon`), shame lexicon
    // (`failure` / `should` / `must` / `behind`), threat lexicon (`scary` /
    // `germ` / `panic`). Pinned by phase3AchievementsTraumaSafeRegister
    // stoplist test. XP band 60-120 matches the Phase 2 spread.
    public static let handwashHero = AchievementDefinition(
        id: "ml.handwash-hero",
        title: "Hands That Care",
        description: "You learned how a quiet wash keeps the microbiome neighborhood balanced.",
        iconAssetName: "hands.sparkles.fill",
        xpValue: 60
    )
    public static let vaccinePrimer = AchievementDefinition(
        id: "ml.vaccine-primer",
        title: "Library Primer",
        description: "You watched the B-cell library learn a new shape — that's how a vaccine works.",
        iconAssetName: "books.vertical.fill",
        xpValue: 80
    )
    public static let antibioticSteward = AchievementDefinition(
        id: "ml.antibiotic-steward",
        title: "Quiet Steward",
        description: "You let the microbiome recover after antibiotic care — slow is wise.",
        iconAssetName: "leaf.fill",
        xpValue: 100
    )
    public static let outbreakHelper = AchievementDefinition(
        id: "ml.outbreak-helper",
        title: "Helper at the Window",
        description: "You learned how a community looks after each other when the microbiome shifts.",
        iconAssetName: "person.2.fill",
        xpValue: 120
    )

    public static let phase3: [AchievementDefinition] = [
        handwashHero, vaccinePrimer, antibioticSteward, outbreakHelper,
    ]

    // MARK: - Phase 4 (8 advanced milestones — paired with Phase 4 surfaces)

    /// First extremophile cast member discovered (Crenarch / Acido / Cryo /
    /// Baro from PR #151). Recognizes the kid's curiosity at the edges of the
    /// catalog, never frames un-discovered extremophiles as a deficit.
    public static let extremophileExplorer = AchievementDefinition(
        id: "ml.extremophile-explorer",
        title: "Edge Explorer",
        description: "You met a microbe that thrives where the air is hot — or cold, or salty, or deep.",
        iconAssetName: "thermometer.sun",
        xpValue: 80
    )

    /// All 4 extremophile cast members discovered. Wonder + adaptation pride
    /// register per ADR-016 — never frames pre-meeting as failure.
    public static let extremophileQuartet = AchievementDefinition(
        id: "ml.extremophile-quartet",
        title: "Wonder at the Edge",
        description: "You met all four edge-dwellers — Crenarch, Acido, Cryo, and Baro. The catalog has corners now.",
        iconAssetName: "globe.americas",
        xpValue: 140
    )

    /// All 4 global-microbiome tour stops visited. Bridges to bioforge /
    /// ecosphere per the cross-portfolio cluster framing. Predicate wiring
    /// lands when the global-tour view ships.
    public static let globalTourist = AchievementDefinition(
        id: "ml.global-tourist",
        title: "Cross-World Traveler",
        description: "You saw what lives in a hot spring, a deep-sea vent, a human gut, and the soil underground.",
        iconAssetName: "map.fill",
        xpValue: 120
    )

    /// First seasonal active event observed (winter cold / spring allergy /
    /// summer warm / autumn settle). Recognition of seasonal noticing.
    public static let seasonalAwareness = AchievementDefinition(
        id: "ml.seasonal-awareness",
        title: "Season Settler",
        description: "You noticed how the microbiome shifts as the seasons change. The body keeps a calendar too.",
        iconAssetName: "leaf.circle",
        xpValue: 60
    )

    /// Completion of kit 15 microbiome-research (anti-credentialism register
    /// per CQ CONTENT_STYLE_GUIDE.md § 4.5). Fires only after the kit lands
    /// reviewer-signed-off per ADR-016.
    public static let researchSeed = AchievementDefinition(
        id: "ml.research-seed",
        title: "First Notebook Page",
        description: "You asked a microbe a question — and watched patient observation answer it.",
        iconAssetName: "book.fill",
        xpValue: 100
    )

    /// Completion of kit 16 synthesis (cumulative-arc warmth register).
    /// Fires only after the kit lands reviewer-signed-off per ADR-016.
    public static let synthesisFinish = AchievementDefinition(
        id: "ml.synthesis-finish",
        title: "Field Naturalist",
        description: "You noticed something across every part of the microbe world. A whole-system noticing.",
        iconAssetName: "binoculars.fill",
        xpValue: 160
    )

    /// Full 24-microbe cast discovered (cast-master at 24/24 — auto-rescales
    /// from PR #119 12-cast → PR #151 24-cast via catalog.microbes.count).
    /// Same warm register as PR #76's codex axis.
    public static let microbeStudent = AchievementDefinition(
        id: "ml.microbe-student",
        title: "Tended the Cast",
        description: "Every microbe in the catalog knows you now. The whole community has met you.",
        iconAssetName: "person.3.fill",
        xpValue: 120
    )

    /// 30 sessions completed without ever hitting the daily cap (recognition
    /// of self-paced exploration over grind). Predicate-wiring against
    /// DailyTimeCoordinator + SessionCountStore lands when the surface ships.
    public static let quietSteward = AchievementDefinition(
        id: "ml.quiet-steward",
        title: "Quiet Steward of Wonder",
        description: "You came back, looked, and let the microbes be. That's stewardship — quiet kind.",
        iconAssetName: "hand.raised.fill",
        xpValue: 80
    )

    public static let phase4: [AchievementDefinition] = [
        extremophileExplorer, extremophileQuartet, globalTourist,
        seasonalAwareness, researchSeed, synthesisFinish, microbeStudent,
        quietSteward,
    ]

    /// Aggregate accessor — every shipped achievement across all phases.
    /// Consumers wanting the full set (Progress tab, ForgeReporting
    /// snapshots, achievement-engine registration) prefer this over
    /// concatenating per-phase arrays.
    public static var allDefinitions: [AchievementDefinition] {
        phase1 + phase2 + phase3 + phase4
    }
}

/// Lightweight gamification facade: wraps ForgeGamification primitives
/// (XPEngine + StreakManager + AchievementEngine) and exposes a single
/// MainActor `@Observable` surface SwiftUI can read.
///
/// Per `.claude/rules/workflow.md` § Service Architecture: ViewModels (not
/// singletons). Construct once at app boot; pass through the view hierarchy.
@MainActor
@Observable
public final class GamificationService {
    public private(set) var totalXP: Int
    public private(set) var earnedAchievementSlugs: Set<String>
    public private(set) var currentStreak: Int
    public private(set) var longestStreak: Int

    public let xpEngine: XPEngine
    public let achievementEngine: AchievementEngine
    public let streakManager: StreakManager
    /// Optional persistence sink. When present, `recordSession` writes the
    /// post-update counters back so cold-launch reads see the latest state.
    private let streakStore: StreakStore?

    public init(
        totalXP: Int = 0,
        earnedAchievementSlugs: Set<String> = [],
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        availableFreezes: Int = 2,
        streakStore: StreakStore? = nil
    ) {
        self.totalXP = totalXP
        self.earnedAchievementSlugs = earnedAchievementSlugs
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.streakStore = streakStore
        self.xpEngine = XPEngine()
        self.achievementEngine = AchievementEngine()
        self.streakManager = StreakManager(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            availableFreezes: availableFreezes
        )
    }

    /// Hydrate from a persisted `StreakStore`. The store is read at app boot
    /// so the GamificationService surface reflects yesterday's state on
    /// today's cold launch.
    public static func hydrated(from store: StreakStore) -> GamificationService {
        GamificationService(
            currentStreak: store.currentStreak,
            longestStreak: store.longestStreak,
            availableFreezes: store.availableFreezes,
            streakStore: store
        )
    }

    public var currentLevel: Int {
        xpEngine.level(for: totalXP)
    }

    public var xpProgress: Double {
        xpEngine.xpProgress(currentXP: totalXP)
    }

    public var xpForNextLevel: Int {
        xpEngine.xpRequired(forLevel: currentLevel + 1)
    }

    /// Award XP — no daily cap in Phase 1 since the app surface is short.
    public func awardXP(_ amount: Int, reason: String) {
        guard amount > 0 else { return }
        totalXP += amount
        DebugLog.state("GamificationService awardXP \(amount) for \(reason); total=\(totalXP) level=\(currentLevel)")
    }

    /// Evaluate the shipped achievement set (Phase 1 + Phase 2) against
    /// the provided criteria closure. Newly-earned achievements are added
    /// to the earned set and returned for celebration UI.
    @discardableResult
    public func evaluateAchievements(
        with criteria: (AchievementDefinition) -> Bool
    ) -> [AchievementDefinition] {
        let newlyEarned = achievementEngine.evaluate(
            definitions: MicrobeLabAchievements.allDefinitions,
            earnedIDs: earnedAchievementSlugs,
            isEarned: criteria
        )
        for definition in newlyEarned {
            earnedAchievementSlugs.insert(definition.id)
            awardXP(definition.xpValue, reason: "achievement \(definition.id)")
        }
        return newlyEarned
    }

    /// Mark a session as recorded — drives the streak surface. Persists the
    /// new counters to the injected `StreakStore` when present so cold-launch
    /// reads see the up-to-date state.
    public func recordSession(date: Date = .now) async {
        let result = await streakManager.recordSession(date: date)
        currentStreak = await streakManager.currentStreak
        longestStreak = await streakManager.longestStreak
        let availableFreezes = await streakManager.availableFreezes
        streakStore?.save(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            availableFreezes: availableFreezes,
            recordedAt: date
        )
        DebugLog.state("GamificationService streak update: \(result); current=\(currentStreak) longest=\(longestStreak)")
    }
}
