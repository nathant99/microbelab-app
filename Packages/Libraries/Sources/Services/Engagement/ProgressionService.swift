import Foundation
import ForgeProgression

/// `@Observable` wrapper around `ForgeProgression.ForgeProgressionManager` for
/// MicrobeLab's session-count-aware in-app gates. Distinct from
/// `AdaptiveImmunityUnlock` (per-encounter, pedagogy-sequencing gate) and
/// distinct from the AdventureHub-side gating on mode-cards (per
/// `Docs/FEATURE_PLAN.md` Phase 2 § "Wire ForgeProgressionManager gating
/// across mode-cards" — that line items closes hub-side, not here).
///
/// **Scope** (per `Docs/TECHNICAL_DESIGN.md` § Phase 3 & 4):
/// in-app session-day-aware gating for Phase 3 (disease-story narratives) and
/// Phase 4 (global microbiome tour) surfaces. Both phases need the kid to
/// have built up enough context across multiple sessions + reached specific
/// scene milestones before disease-story arcs or the global tour unlock.
/// ForgeProgressionManager's session-count + secondary-criteria model fits
/// this naturally.
///
/// **Trauma-informed posture**: gates surface "X more days to unlock the
/// disease-story arc" copy via `unlockHint(for:)`, never "you failed" or
/// "behind". The `simplifyChallenge` parent-gated bypass would short-circuit
/// these gates the same way it short-circuits adaptive-immunity gating; that
/// hook lands when Phase 3 wiring actually consumes the gates (this PR ships
/// the scaffold without the consuming surfaces).
@MainActor
@Observable
public final class ProgressionService {

    public static let diseaseStoryImmuneGateID = "disease-story-immune"
    public static let diseaseStoryMicrobiomeGateID = "disease-story-microbiome"
    public static let globalMicrobiomeTourGateID = "global-microbiome-tour"

    /// Metric key: cumulative count of innate-immune game completions.
    /// Tracked because the disease-story-immune arc needs the kid to have
    /// internalized the macrophage / B-cell distinction first.
    public static let immuneRunsMetricKey = "immune.runs.completed"

    /// Metric key: cumulative count of microbiome-puzzle scene visits across
    /// all ecology surfaces. Tracked because the disease-story-microbiome arc
    /// needs the kid to have engaged with at least one ecology before the
    /// dysbiosis-story angle lands gently.
    public static let microbiomeSceneMetricKey = "microbiome.scene.visited"

    /// Metric key: cumulative count of distinct ecology scenes visited (oral
    /// / skin / soil / freshwater). Phase 4 global-microbiome-tour needs all
    /// four to have been explored before the world tour is contextual.
    public static let ecologyScenesVisitedMetricKey = "ecology.scenes.distinct"

    private var manager: ForgeProgressionManager

    public init(persistenceKey: String = "MicrobeLabProgression") {
        var manager = ForgeProgressionManager(
            gates: ProgressionService.canonicalGates(),
            persistenceKey: persistenceKey
        )
        manager.loadPersisted()
        self.manager = manager
    }

    // MARK: - Session recording

    /// Records a new session. The underlying manager dedupes by calendar
    /// day — multiple calls in one calendar day count as one session.
    /// Returns `true` if a new session-day was recorded.
    @discardableResult
    public func recordSession(date: Date = .now) -> Bool {
        let didRecord = manager.recordSession(date: date)
        if didRecord {
            manager.persist()
        }
        return didRecord
    }

    // MARK: - Metric recording

    /// Increments the immune-runs counter by 1 (called after a completed
    /// macrophage / B-cell scene run).
    public func recordImmuneRunCompleted() {
        manager.incrementMetric(Self.immuneRunsMetricKey, by: 1)
        manager.persist()
    }

    /// Increments the microbiome-scene-visited counter by 1 (called when the
    /// kid enters any ecology scene). Distinct ecology tracking is handled
    /// separately via `recordEcologyScenesVisited(distinctCount:)`.
    public func recordMicrobiomeSceneVisited() {
        manager.incrementMetric(Self.microbiomeSceneMetricKey, by: 1)
        manager.persist()
    }

    /// Sets the distinct-ecology-scenes-visited count. Caller computes the
    /// distinct count (e.g., from `Set<EcologyScene>` in the calling view).
    /// Using `recordMetric` (not `incrementMetric`) because distinct-count is
    /// a derived value, not a cumulative increment.
    public func recordEcologyScenesVisited(distinctCount: Int) {
        manager.recordMetric(Self.ecologyScenesVisitedMetricKey, value: max(0, distinctCount))
        manager.persist()
    }

    // MARK: - Gate evaluation

    /// Returns `true` iff the gate has been unlocked (session count + all
    /// secondary criteria met).
    public func isUnlocked(_ gateID: String) -> Bool {
        manager.isUnlocked(gateID)
    }

    /// Returns the trauma-informed unlock-hint copy for a locked gate, or
    /// `nil` if the gate is already unlocked or not registered.
    public func unlockHint(for gateID: String) -> String? {
        manager.unlockHint(for: gateID)
    }

    /// Returns per-criterion progress for UI display.
    public func unlockProgress(for gateID: String) -> [CriterionProgress] {
        manager.unlockProgress(for: gateID)
    }

    /// Returns the count of additional sessions required for the named gate.
    public func sessionsRemaining(for gateID: String) -> Int {
        manager.sessionsRemaining(for: gateID)
    }

    /// Current session-day count.
    public var sessionCount: Int { manager.sessionCount }

    /// Current value of a tracked metric.
    public func metricValue(for key: String) -> Int {
        manager.metricValue(for: key)
    }

    // MARK: - Debug bypass

    /// Test / debug only: marks every gate as unlocked regardless of session
    /// count or secondary criteria. Intended for QA / accessibility-audit
    /// flows + future XCUITest launch-argument bypass.
    public func debugUnlockAllGates() {
        manager.debugUnlockAllGates()
    }

    /// Test / debug only: restores normal gate evaluation.
    public func debugRestoreGateEvaluation() {
        manager.debugRestoreGateEvaluation()
    }

    /// Reset session-day count + all metrics. Intended for QA / test setup
    /// only — never wired into a user-facing surface.
    public func resetForTest() {
        manager.reset()
    }

    // MARK: - Canonical gates

    /// Three Phase-3+ gates. Each is independently consumable by future
    /// Phase 3 / Phase 4 work without re-touching this seam. Session
    /// thresholds calibrated to a kid playing ~5-15 minutes per session per
    /// the engagement-foundation cadence (DailyTimeCoordinator).
    public static func canonicalGates() -> [ContentGate] {
        [
            // Disease-story-immune: surfaces the immune-system-disease arc
            // (Phase 3) once the kid has played across 5 distinct days AND
            // completed at least 3 macrophage / B-cell runs. The pedagogy
            // arc — "the immune system is the body's neighborhood watch" —
            // only lands gently when the kid has internalized the cast.
            ContentGate(
                id: diseaseStoryImmuneGateID,
                requiredSessions: 5,
                displayName: "Immune-system disease stories",
                unlockHint: "Play across 5 different days and complete 3 immune runs to meet the disease-story arc.",
                secondaryCriteria: [
                    SecondaryCriterion(
                        metricKey: immuneRunsMetricKey,
                        requiredValue: 3,
                        displayLabel: "Immune runs completed",
                        conjunction: .and
                    ),
                ]
            ),
            // Disease-story-microbiome: surfaces the gut / dysbiosis arc
            // (Phase 3) once the kid has played across 5 distinct days AND
            // visited any microbiome scene at least 5 times. Dysbiosis is a
            // sensitive frame — the kid needs to have experienced "the
            // neighborhood thrives" before the "what happens when it
            // doesn't" story lands without alarm.
            ContentGate(
                id: diseaseStoryMicrobiomeGateID,
                requiredSessions: 5,
                displayName: "Microbiome disease stories",
                unlockHint: "Play across 5 different days and visit any microbiome scene 5 times to meet the dysbiosis arc.",
                secondaryCriteria: [
                    SecondaryCriterion(
                        metricKey: microbiomeSceneMetricKey,
                        requiredValue: 5,
                        displayLabel: "Microbiome scenes visited",
                        conjunction: .and
                    ),
                ]
            ),
            // Global microbiome tour: surfaces the Yellowstone /
            // deep-sea-vent / soil bridge (Phase 4) once the kid has played
            // across 8 distinct days AND explored all 4 in-app ecologies
            // (freshwater + oral + skin + soil). The tour assumes the kid
            // has the per-ecology vocabulary to compare extremophiles to
            // their familiar microbe friends.
            ContentGate(
                id: globalMicrobiomeTourGateID,
                requiredSessions: 8,
                displayName: "Global microbiome tour",
                unlockHint: "Play across 8 different days and explore all 4 microbiome scenes to unlock the global tour.",
                secondaryCriteria: [
                    SecondaryCriterion(
                        metricKey: ecologyScenesVisitedMetricKey,
                        requiredValue: 4,
                        displayLabel: "Distinct ecologies explored",
                        conjunction: .and
                    ),
                ]
            ),
        ]
    }
}
