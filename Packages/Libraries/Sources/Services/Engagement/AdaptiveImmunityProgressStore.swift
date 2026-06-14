import Foundation
import Observation

/// Persists cumulative innate-immunity run counts so the
/// `AdaptiveImmunityUnlock` derivation has the data it needs across
/// sessions. Counts are purely additive — never decremented — per the
/// trauma-informed posture (a kid's previous runs are never "taken away"
/// by a reset).
///
/// Storage: UserDefaults, mirrors the `DiscoveryStore` / `SessionCountStore`
/// pattern. On-device only per `.claude/rules/age-assurance.md` § Portfolio
/// Status — counts only, no PII.
///
/// Wiring path (consumers):
/// 1. `AppRootView` instantiates one canonical store + threads through
///    `MicrobeCodexView` → `ImmuneGameView`.
/// 2. `ImmuneGameView` calls `recordRunCompleted(perfectRun:)` when the
///    `MacrophagePacmanScene.clearWave()` returns `finished == true`. The
///    `perfectRun` flag mirrors the `MasteryMomentDetector` perfect-run
///    gate (all waves cleared AND zero pathogens missed).
/// 3. `ImmuneGameView` reads `AdaptiveImmunityUnlock.from(
///    innateRunsCompleted: store.innateRunsCompleted,
///    perfectInnateRuns: store.perfectInnateRuns,
///    simplifyChallenge: settings.simplifyChallenge)` to decide whether
///    the adaptive mode picker is available.
@MainActor
@Observable
public final class AdaptiveImmunityProgressStore {
    public static let runsKey = "com.microbelab.adaptive.innateRunsCompleted"
    public static let perfectRunsKey = "com.microbelab.adaptive.perfectInnateRuns"

    public private(set) var innateRunsCompleted: Int
    public private(set) var perfectInnateRuns: Int

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.innateRunsCompleted = max(0, defaults.integer(forKey: Self.runsKey))
        self.perfectInnateRuns = max(0, defaults.integer(forKey: Self.perfectRunsKey))
    }

    /// Record a finished innate run. Pure-additive. Idempotency is the
    /// caller's responsibility (the immune-game's `clearWave()` return
    /// already gates on `finished == true`).
    public func recordRunCompleted(perfectRun: Bool) {
        innateRunsCompleted += 1
        defaults.set(innateRunsCompleted, forKey: Self.runsKey)
        if perfectRun {
            perfectInnateRuns += 1
            defaults.set(perfectInnateRuns, forKey: Self.perfectRunsKey)
        }
    }

    /// Derived unlock state. Wraps the pure
    /// `AdaptiveImmunityUnlock.from(...)` derivation so consumers don't
    /// have to thread both counts independently.
    public func unlock(simplifyChallenge: Bool = false) -> AdaptiveImmunityUnlock {
        AdaptiveImmunityUnlock.from(
            innateRunsCompleted: innateRunsCompleted,
            perfectInnateRuns: perfectInnateRuns,
            simplifyChallenge: simplifyChallenge
        )
    }

    /// Wipe persisted state. Test-only — the production surface never
    /// shrinks a kid's completed runs.
    public func clearForTesting() {
        innateRunsCompleted = 0
        perfectInnateRuns = 0
        defaults.removeObject(forKey: Self.runsKey)
        defaults.removeObject(forKey: Self.perfectRunsKey)
    }
}
