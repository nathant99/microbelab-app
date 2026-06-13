import Foundation
import Observation
import ForgeAnalytics
import Models

/// MainActor `@Observable` wrapper around `ForgeAnalytics.AnalyticsEngine` (an
/// actor) so SwiftUI views can call `analytics.track(...)` without ceremony
/// while every recorded event still lands inside the COPPA-safe on-device
/// analytics engine.
///
/// Per `.claude/rules/age-assurance.md` § Portfolio Status and CLAUDE.md
/// § ForgeAnalytics: privacy-first — every event stays on-device, no
/// third-party SDK / no network transmission. `ForgeAnalytics`'s built-in PII
/// blocklist filters property keys at recording time.
///
/// Per `Docs/IMPLEMENTATION_HANDOFF.md` § ForgeKit Integration Status,
/// `ForgeAnalytics` was previously declared-but-unused; this service is the
/// first consumer surface.
@MainActor
@Observable
public final class AnalyticsService {
    private let engine: AnalyticsEngine
    public private(set) var currentSessionID: UUID?

    public init(config: AnalyticsConfig = AnalyticsConfig()) {
        self.engine = AnalyticsEngine(config: config)
    }

    /// Starts a new analytics session and stamps `currentSessionID` so views
    /// can observe whether the engine is recording.
    public func startSession() async {
        let id = await engine.startSession()
        currentSessionID = id
    }

    /// Ends the current session and clears `currentSessionID`. Safe to call
    /// when no session is active (no-op).
    public func endSession() async {
        _ = await engine.endSession()
        currentSessionID = nil
    }

    /// Track a MicrobeLab-canonical event. The event's `properties` payload
    /// already excludes PII by construction (the event types ship only
    /// integer + enum payloads), but the engine's blocklist runs anyway as a
    /// belt-and-suspenders check.
    public func track(_ event: MicrobeLabAnalyticsEvent) async {
        await engine.track(event.name, properties: event.properties)
    }

    /// Number of distinct calendar-days with at least one recorded event in
    /// the last N days. Used by D1 / D7 / D30 surfacing without needing the
    /// app-side `RetentionMetricsStore` to duplicate the bookkeeping.
    public func activeDays(last days: Int) async -> Int {
        await engine.activeDays(last: days)
    }

    /// Total events recorded across all sessions still inside the engine's
    /// retention window. Surface in debug menus + parent-facing dashboards.
    public func totalEventCount() async -> Int {
        await engine.eventCount
    }

    /// Snapshot of every event name recorded so far. Used in unit tests to
    /// assert that a particular event landed in the engine; not for kid-
    /// facing surfaces.
    public func recordedEventNames() async -> [String] {
        await engine.exportEvents().map(\.name)
    }
}

/// Canonical MicrobeLab analytics events. Adding a new event class is a
/// type-safe extension here — adopting code never spells the event name as a
/// raw string, so the analytics surface stays grep-able.
///
/// Properties are intentionally small: the kid's tier reached, the wave
/// index they cleared, the tick count where a milestone landed. No
/// kid-identifying information; per
/// `.claude/rules/age-assurance.md` § Portfolio Status the property bag is
/// counts + enum slugs only.
public enum MicrobeLabAnalyticsEvent: Sendable, Equatable {
    /// Kid pinch-snapped to a new microscope tier.
    case zoomTierReached(tier: ZoomTier)
    /// Microbiome simulator reached a multiple-of-5 tick milestone.
    case microbiomeMilestone(tickCount: Int)
    /// Kid cleared a wave of the innate-immunity minigame.
    case immuneWaveCleared(waveIndex: Int)
    /// Kid finished the entire innate-immunity minigame run.
    case immuneRunCompleted
    /// Kid changed the feeding mode in the microbiome simulator.
    case feedingModeChanged(modeSlug: String)
    /// Kid completed a question kit.
    case quizCompleted(kitSlug: String, correct: Int, total: Int)
    /// Kid earned an achievement.
    case achievementEarned(slug: String)
    /// AppRootView transitioned to a new startup / steady-state phase.
    /// Payload is the canonical slug from `MicrobeLabPhase.slug` so the
    /// event surface stays grep-stable. Emitted on the boundary of
    /// `parent_handoff` → `kid_onboarding` → `loading_catalog` →
    /// `tab_shell` / `catalog_failure`.
    case appPhaseReached(phaseSlug: String)

    /// Canonical event name (snake_case per portfolio analytics convention).
    public var name: String {
        switch self {
        case .zoomTierReached: return "zoom_tier_reached"
        case .microbiomeMilestone: return "microbiome_milestone"
        case .immuneWaveCleared: return "immune_wave_cleared"
        case .immuneRunCompleted: return "immune_run_completed"
        case .feedingModeChanged: return "feeding_mode_changed"
        case .quizCompleted: return "quiz_completed"
        case .achievementEarned: return "achievement_earned"
        case .appPhaseReached: return "app_phase_reached"
        }
    }

    /// Property bag for the event. Keys lowercase + non-PII per the engine's
    /// default blocklist; the values are always slugs or counts.
    public var properties: [String: String] {
        switch self {
        case .zoomTierReached(let tier):
            return ["tier_slug": tier.slug, "tier_index": "\(tier.rawValue)"]
        case .microbiomeMilestone(let tickCount):
            return ["tick_count": "\(tickCount)"]
        case .immuneWaveCleared(let waveIndex):
            return ["wave_index": "\(waveIndex)"]
        case .immuneRunCompleted:
            return [:]
        case .feedingModeChanged(let modeSlug):
            return ["mode_slug": modeSlug]
        case .quizCompleted(let kitSlug, let correct, let total):
            return [
                "kit_slug": kitSlug,
                "correct_count": "\(correct)",
                "total_count": "\(total)",
                "perfect": correct == total ? "true" : "false",
            ]
        case .achievementEarned(let slug):
            return ["achievement_slug": slug]
        case .appPhaseReached(let phaseSlug):
            return ["phase_slug": phaseSlug]
        }
    }
}

private extension ZoomTier {
    /// Stable slug used in analytics properties. Avoids leaking the
    /// integer-raw-value choice + makes parent-dashboard event filters
    /// readable.
    var slug: String {
        switch self {
        case .unaided: return "unaided"
        case .light: return "light"
        case .fluorescence: return "fluorescence"
        case .electron: return "electron"
        }
    }
}
