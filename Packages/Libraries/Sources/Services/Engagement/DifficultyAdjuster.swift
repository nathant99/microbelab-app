import Foundation

/// Coarse difficulty band the rest of the app reads to pick wave counts,
/// achievement thresholds, etc. Bands are intentionally low-resolution so
/// the kid never feels rubber-banded mid-session — adjustments happen at
/// session boundaries, not between waves.
public nonisolated enum DifficultyLevel: Sendable, Equatable, CaseIterable {
    /// Sessions 1-2 (or any session when the kid has flagged "make it
    /// gentler" via Settings). Fewer pathogens per wave, lower steady-tick
    /// threshold so the microbiome achievements unlock without a long grind.
    case introductory
    /// Sessions 3-4 + the first few sessions after a long absence. Stock
    /// Phase-1 wave counts; default 10-tick steady threshold.
    case standard
    /// Sessions 5+ with at least one full immune-game clear under the belt.
    /// Slightly denser waves; same steady threshold (we don't tighten
    /// time-on-task; only spatial density).
    case challenging
}

/// Pure-value DDA surface. Per `Docs/FEATURE_PLAN.md` § Engagement
/// Foundation → "DDA engine — Invisible difficulty adjustment across
/// microbiome puzzles + immune game wave count."
///
/// Adjustment is **invisible**: the kid never sees a "difficulty: easy"
/// label. The only consumer-facing knob is the parent-gated
/// `AppSettings.forceSimplifyChallenge` switch (added alongside this
/// service); when on, the adjuster pins to `.introductory` regardless of
/// session count.
///
/// The surface is intentionally tiny — two queries (wave pathogen counts +
/// stability tick threshold) — so future signals (e.g., immune-game
/// reset count, microbiome-tab abandonment rate) can extend the input set
/// without rippling through every consumer.
///
/// **Trauma-informed posture** (per `.claude/rules/trauma-informed-content.md`):
/// the curve only ever ramps UP from `.introductory`. There is no "punish
/// failure" branch — repeated resets do not escalate difficulty. This is a
/// gentle adaptive band, not a feedback-driven competitive system.
public nonisolated struct DifficultyAdjuster: Sendable, Equatable {
    public let level: DifficultyLevel

    public init(level: DifficultyLevel) {
        self.level = level
    }

    /// Derive a difficulty band from the current session count + the
    /// player's accessibility preference.
    ///
    /// - Parameters:
    ///   - sessionCount: current `SessionCountStore.sessionCount`. 0 means
    ///     the kid hasn't completed onboarding yet; treated as session 1.
    ///   - simplifyChallenge: when true (parent-gated Settings toggle),
    ///     force `.introductory` regardless of session count.
    public static func from(
        sessionCount: Int,
        simplifyChallenge: Bool = false
    ) -> DifficultyAdjuster {
        if simplifyChallenge {
            return DifficultyAdjuster(level: .introductory)
        }
        switch sessionCount {
        case ..<3: return DifficultyAdjuster(level: .introductory)
        case 3...4: return DifficultyAdjuster(level: .standard)
        default: return DifficultyAdjuster(level: .challenging)
        }
    }

    /// Per-wave pathogen counts for the innate-immunity Pac-Man minigame.
    /// Replaces the hardcoded `[4, 6, 8, 10, 12]` in `MacrophagePacmanScene`.
    ///
    /// The curve always climbs across waves WITHIN a session (kids expect
    /// progress); the BAND shifts the floor + ceiling per difficulty level.
    public func immuneWavePathogenCounts(totalWaves: Int = 5) -> [Int] {
        precondition(totalWaves >= 1, "totalWaves must be >= 1")
        let (start, step) = waveCurve()
        return (0..<totalWaves).map { wave in
            start + step * wave
        }
    }

    /// Threshold of consecutive perturbation-free ticks before the
    /// `microbiomeSteady` achievement unlocks. Lowered at `.introductory`
    /// so the kid feels the milestone without a long grind during the first
    /// sessions.
    public var microbiomeSteadyTickThreshold: Int {
        switch level {
        case .introductory: return 6
        case .standard: return 10
        case .challenging: return 14
        }
    }

    private func waveCurve() -> (start: Int, step: Int) {
        switch level {
        case .introductory:
            // Smallest opener + gentlest ramp so the kid can taste the loop
            // without feeling overwhelmed at the trauma-informed off-ramp.
            return (start: 3, step: 1)
        case .standard:
            // Stock Phase-1 curve: 4, 6, 8, 10, 12 — codified in
            // `MacrophagePacmanScene.init` before this DDA surface landed.
            return (start: 4, step: 2)
        case .challenging:
            // Denser opener so the kid who's already cleared the game feels
            // the bump. Ramp stays the same; we don't tighten cognitive
            // load mid-run.
            return (start: 5, step: 2)
        }
    }
}
