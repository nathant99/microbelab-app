import Foundation
import ForgeEvents

/// `@Observable` wrapper around `ForgeEvents.ForgeEventEngine` for
/// MicrobeLab's Phase 4 seasonal-pack surface.
///
/// **Scope** (per `Docs/TECHNICAL_DESIGN.md` § Phase 4): the Phase 4
/// experiment `seasonal_content_gate` (scaffolded PR #136 via
/// `ExperimentsService`) flips a seasonal pack on/off; when ON,
/// `SeasonalEventService.refresh(on:)` updates `activeEvents` + the
/// `hasActiveEvent` / `streakEmoji` / `currencyEmoji` derived signals
/// that UI surfaces (Progress / Profile / Welcome-Back overlay) read.
///
/// **Pack selection rationale** (per `.claude/rules/distributed-narrative.md`
/// § cultural-respect + `.claude/rules/age-assurance.md` § COPPA): defaults
/// to the kid-safe, culturally-neutral packs only — `.seasons` (spring /
/// summer / fall / winter) + `.globalCelebrations` (Earth Day / New Year /
/// World Teachers' Day / etc.). Region- or religion-specific packs
/// (`.vietnameseHolidays` / `.indianCelebrations` / `.latinoCelebrations` /
/// `.americanHolidays`) ship as opt-in only — settings can enable them via
/// `setEnabledPacks(_:)` after a parent-gated handoff. The default ships
/// neutral packs so first-launch never assumes the kid's culture.
///
/// **Trauma-informed posture**: seasonal events surface ONLY as gentle UI
/// affordances (background tints / icon swaps / streak emoji). The
/// `ForgeEventEngine` collectible-hunt + daily-quest configs are NOT wired
/// in this PR — those land in a separate round after the parent-handoff
/// extension picks up an "Include seasonal challenges" opt-in toggle.
///
/// **Why so minimal**: per the user-direct scope discipline + the eleven-pass
/// canonical-invariant tier in `CLAUDE.md` § Xcode-managed file safety, this
/// PR ships the orchestrator + a Phase 4 surface scaffold ONLY. View
/// consumers (the seasonal background tint, the streak-emoji swap) land in
/// a future round when the `ExperimentsService.seasonal_content_gate`
/// experiment flips to a non-zero treatment weight.
@MainActor
@Observable
public final class SeasonalEventService {

    /// Default packs enabled at first launch — culturally neutral so the
    /// app never assumes the kid's identity before a parent opts into a
    /// specific cultural pack.
    public static let defaultEnabledPacks: Set<ForgeCelebrationPack> = [
        .seasons,
        .globalCelebrations
    ]

    public private(set) var enabledPacks: Set<ForgeCelebrationPack>
    public private(set) var hasRefreshed: Bool = false

    private let registry: ForgeEventRegistry
    public let engine: ForgeEventEngine

    public init(
        enabledPacks: Set<ForgeCelebrationPack> = SeasonalEventService.defaultEnabledPacks
    ) {
        let registry = ForgeEventRegistry()
        self.registry = registry
        self.engine = ForgeEventEngine(registry: registry)
        self.enabledPacks = enabledPacks
    }

    /// Register the ForgeEvents built-in catalog (41 holidays across the
    /// seven packs). Idempotent — `ForgeEventRegistry.register(_:)` checks
    /// for duplicates by id. Call once at app launch.
    public func registerBuiltIns() async {
        await registry.registerBuiltInEvents()
    }

    /// Refresh `activeEvents` + derived signals for the given date. Pair
    /// with the app's daily-rollover hook (e.g. `LastActiveStore`) so the
    /// active set tracks the kid's local day.
    public func refresh(on date: Date = .now) async {
        await engine.refresh(on: date, enabledPacks: enabledPacks)
        hasRefreshed = true
    }

    /// Update the enabled-packs set (e.g. after a parental settings handoff
    /// turns on `.americanHolidays`). The next `refresh(on:)` picks up the
    /// new set.
    public func setEnabledPacks(_ packs: Set<ForgeCelebrationPack>) {
        enabledPacks = packs
    }

    /// True when the engine surfaces at least one active event today.
    /// Consuming views read this to gate the seasonal-tint affordance.
    public var hasActiveEvent: Bool { engine.hasActiveEvent }

    /// Streak emoji override surfaced when an event is active (e.g. 🍂
    /// during fall). Nil when no event provides a streak emoji.
    public var streakEmoji: String? { engine.streakEmoji }

    /// Currency emoji override surfaced when an event is active. Nil when
    /// no event provides a currency emoji.
    public var currencyEmoji: String? { engine.currencyEmoji }
}
