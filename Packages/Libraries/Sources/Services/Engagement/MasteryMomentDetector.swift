import Foundation
import Models

/// Tracks the kid's Phase-1 mastery moments — distinct events fired when the kid demonstrates
/// internalization of a Phase-1 system (ecology / defense / discovery). Pure nonisolated value
/// type so it can be carried as `@State` in SwiftUI views without observation overhead.
///
/// Per `Docs/FEATURE_PLAN.md` § Delight & Polish → "Mastery moments — Distinct screen ripple
/// + chord when child internalizes microbiome ecology": the detector watches simulator state
/// and surfaces a `MasteryMoment` once per session per kind. Repeated achievement of the same
/// criterion in the same session is a no-op (acknowledged set); cold launches reset.
///
/// Trauma-informed posture: mastery moments NEVER frame the kid's prior runs as "you almost
/// had it" or "you finally got it" — they frame the moment as "you've internalized this", a
/// quiet recognition of pattern learning, not loss-aversion or grade-style mastery levels.
///
/// Wiring path:
/// - `MicrobiomeView` calls `recordEcologyTick(stableTickRun:feedingMode:)` after each
///   simulator tick; the detector returns `.ecologyMaster` when the kid maintains a stable
///   ecology for ≥ 15 consecutive ticks with `.fiber` feeding (demonstrates internalization
///   of feeding-mode → growth-rate causality).
/// - `ImmuneGameView` calls `recordDefenseRunComplete(wavesCleared:pathogensRemaining:)` when
///   a run completes; the detector returns `.defenseMaster` when all 5 waves clear with zero
///   pathogens remaining (perfect defense run).
/// - `MicrobeCodexView` calls `recordCodexDiscovery(totalDiscovered:totalAvailable:)` after
///   each discovery write-through; the detector returns `.codexMaster` when the kid completes
///   the codex (12 / 12 microbes).
///
/// SwiftUI consumers fire a `CelebrationCoordinator.personalBest(metric:value:)` (`.epic`
/// tier) celebration + a `SensoryPaletteCoordinator.streakMilestone(milestone:)` haptic when
/// a moment fires — both surfaces already shipped in earlier rounds.
public nonisolated struct MasteryMomentDetector: Sendable, Equatable {
    public enum MasteryKind: String, Sendable, Equatable, Hashable, CaseIterable {
        case ecologyMaster
        case defenseMaster
        case codexMaster
    }

    public struct Moment: Sendable, Equatable {
        public let kind: MasteryKind
        /// Headline shown in the celebration overlay. Trauma-informed: recognition, not
        /// comparison. Never frames prior runs as failure.
        public let headline: String
        /// Subline carried to mentor bubble copy. Calm, agentic framing.
        public let subline: String
        public init(kind: MasteryKind, headline: String, subline: String) {
            self.kind = kind
            self.headline = headline
            self.subline = subline
        }
    }

    /// Acknowledged moments — once a kind fires in a session, repeated criteria-met events
    /// are no-ops until the next session. Persistence stays in-memory; cold launches reset.
    public private(set) var acknowledged: Set<MasteryKind>

    public init(acknowledged: Set<MasteryKind> = []) {
        self.acknowledged = acknowledged
    }

    /// Mark a `MasteryKind` as acknowledged. Idempotent.
    public mutating func acknowledge(_ kind: MasteryKind) {
        acknowledged.insert(kind)
    }

    // MARK: - Ecology mastery

    /// Threshold (in consecutive stable ticks under `.fiber` feeding) at which the kid is
    /// considered to have internalized the feeding-mode → growth-rate causality. Picked at
    /// 15 because by then the simulator has run through 3 stability-milestone events (every
    /// 5 ticks) — enough for the pattern to land without dragging the moment too late.
    public static let ecologyMasteryStableTickThreshold: Int = 15

    /// Call after each simulator tick. Returns a `.ecologyMaster` `Moment` exactly once per
    /// session when the kid has maintained a stable ecology for ≥ 15 ticks under fiber
    /// feeding. Returns nil for every other state (already-acknowledged / non-fiber mode /
    /// below threshold).
    public mutating func recordEcologyTick(
        stableTickRun: Int,
        feedingMode: FeedingMode
    ) -> Moment? {
        guard !acknowledged.contains(.ecologyMaster) else { return nil }
        guard feedingMode == .fiber else { return nil }
        guard stableTickRun >= Self.ecologyMasteryStableTickThreshold else { return nil }
        acknowledged.insert(.ecologyMaster)
        return Moment(
            kind: .ecologyMaster,
            headline: "Ecology master",
            subline: "You held a stable microbiome for \(stableTickRun) ticks. Your fiber + balance instinct is internalized."
        )
    }

    // MARK: - Defense mastery

    /// Returns a `.defenseMaster` `Moment` exactly once per session when the kid completes
    /// the immune Pac-Man with all 5 waves cleared AND zero pathogens remaining (perfect
    /// defense run). Returns nil otherwise.
    public mutating func recordDefenseRunComplete(
        wavesCleared: Int,
        pathogensRemaining: Int
    ) -> Moment? {
        guard !acknowledged.contains(.defenseMaster) else { return nil }
        guard wavesCleared >= 5 else { return nil }
        guard pathogensRemaining == 0 else { return nil }
        acknowledged.insert(.defenseMaster)
        return Moment(
            kind: .defenseMaster,
            headline: "Defense master",
            subline: "Five waves clear, zero pathogens missed. Your macrophages know the rhythm."
        )
    }

    // MARK: - Codex mastery

    /// Returns a `.codexMaster` `Moment` exactly once per session when the kid completes the
    /// codex (every microbe in the catalog discovered). `totalAvailable` of 0 is a no-op
    /// (defensive — no catalog → no mastery to grant).
    public mutating func recordCodexDiscovery(
        totalDiscovered: Int,
        totalAvailable: Int
    ) -> Moment? {
        guard !acknowledged.contains(.codexMaster) else { return nil }
        guard totalAvailable > 0 else { return nil }
        guard totalDiscovered >= totalAvailable else { return nil }
        acknowledged.insert(.codexMaster)
        return Moment(
            kind: .codexMaster,
            headline: "Codex complete!",
            subline: "You met every microbe in the catalog. The whole cast knows you now."
        )
    }
}
