import Foundation

/// Per `Docs/FEATURE_PLAN.md` § Phase 2 → "Implement adaptive-immunity
/// progression curve (innate-first → adaptive unlocks)". Pure-value gating
/// logic that decides whether the kid has earned access to the B-cell
/// antibody-matching scene (Phase 2 surface) based on how many innate
/// macrophage runs they have completed.
///
/// **Trauma-informed posture** (per `.claude/rules/trauma-informed-content.md`):
/// the gate is never punitive. It is a discovery-sequencing signal — the
/// kid sees how many runs remain to unlock the next surface ("2 more runs
/// to meet the B-cell library"), not a "you failed to unlock" frame. The
/// parent-gated `simplifyChallenge` toggle bypasses the gate entirely so
/// kids with medical anxiety or sensory-overload risk can explore at their
/// own pace without earning their way in.
///
/// **Design pedagogy** (per `Docs/TECHNICAL_DESIGN.md` § Phase 2):
/// adaptive immunity builds on the innate response — the kid first
/// internalizes that macrophages clean up early intruders, then meets the
/// adaptive layer that recognizes shapes and remembers between encounters.
/// Surfacing the adaptive scene before the innate concept lands undermines
/// the pedagogy beat, so the gate keeps them sequenced.
public nonisolated enum AdaptiveImmunityUnlock: Sendable, Equatable {
    /// Kid still needs to complete more innate runs OR achieve a perfect
    /// run before the adaptive surface unlocks. Carries progress for the
    /// UI to render warm "X more runs" copy without leaking a "fail" frame.
    case locked(progress: Double, runsRemaining: Int)
    /// Kid has met the threshold; the adaptive B-cell scene surfaces.
    case unlocked

    /// Number of innate runs required before the adaptive surface unlocks
    /// by the standard path (cumulative; counts every clean run including
    /// non-perfect ones). The perfect-run path unlocks at a single run so
    /// a kid who nails the innate surface first try can immediately
    /// explore the adaptive surface.
    public static let standardRunThreshold = 3

    /// Pure-value derivation from observed innate-run state. Both paths
    /// unlock; the perfect-run path is the fast track for kids who
    /// demonstrate mastery of the innate surface early.
    ///
    /// - Parameters:
    ///   - innateRunsCompleted: cumulative count of finished innate runs
    ///     (all waves cleared); independent of perfect-run status. Always
    ///     non-negative; treats negative as 0.
    ///   - perfectInnateRuns: cumulative count of innate runs that
    ///     completed with zero pathogens missed. Always non-negative;
    ///     treats negative as 0.
    ///   - simplifyChallenge: when true (parent-gated
    ///     `AppSettings.simplifyChallenge` toggle), bypass the gate
    ///     entirely. Kids whose parents have signalled "make it gentler"
    ///     never have to earn their way into the next surface.
    public static func from(
        innateRunsCompleted: Int,
        perfectInnateRuns: Int,
        simplifyChallenge: Bool = false
    ) -> AdaptiveImmunityUnlock {
        if simplifyChallenge {
            return .unlocked
        }
        let runs = max(0, innateRunsCompleted)
        let perfect = max(0, perfectInnateRuns)
        // Fast-track: any perfect run unlocks immediately.
        if perfect >= 1 {
            return .unlocked
        }
        if runs >= standardRunThreshold {
            return .unlocked
        }
        let remaining = standardRunThreshold - runs
        let progress = Double(runs) / Double(standardRunThreshold)
        return .locked(progress: progress, runsRemaining: remaining)
    }

    /// Convenience: `true` iff the adaptive surface should be available.
    public var isUnlocked: Bool {
        if case .unlocked = self { return true }
        return false
    }

    /// Warm UI copy for the locked state. Trauma-informed: frames the
    /// remaining work as discovery sequencing, never as failure. Stoplist
    /// pinned by parameterized test (no `failed` / `behind` / `should` /
    /// `must` / `not yet ready`). Returns `nil` once unlocked so callers
    /// know to dismiss the explainer.
    public var unlockExplainerCopy: String? {
        switch self {
        case .unlocked:
            return nil
        case let .locked(_, runsRemaining):
            if runsRemaining == 1 {
                return "One more innate run to meet the B-cell library."
            }
            return "\(runsRemaining) more innate runs to meet the B-cell library."
        }
    }
}
