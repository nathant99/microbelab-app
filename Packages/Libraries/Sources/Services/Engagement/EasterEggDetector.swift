import Foundation
import Models

/// Tracks the set of zoom tiers a kid has visited within the current
/// session + emits a one-shot "you saw the whole range" easter-egg event
/// when all four tiers have been touched. Per `Docs/FEATURE_PLAN.md`
/// § Delight & Polish → "Easter eggs — Hidden rare-microbe encounters
/// rewarding curious zoom exploration".
///
/// **Pure value type** — owned as `@State` by the consuming view; no
/// persistence, no cross-session memory. Each session restarts the
/// curiosity check from zero so the easter egg can re-trigger as the kid
/// returns over time. Trauma-informed posture: the easter egg never
/// surfaces as loss-aversion ("you missed it") — only as a warm "you saw
/// everything today" beat.
///
/// The selected rare microbe is deterministic per session via a tiny salt
/// + session-count mixer so the slug never flickers between renders.
public nonisolated struct EasterEggDetector: Sendable, Equatable {
    public private(set) var visitedTiers: Set<ZoomTier>
    /// Marked true the FIRST tick on which `visitedTiers` becomes a full
    /// set of all four tiers. Consumers read this once + call
    /// `acknowledgeAllTiersReached()` to suppress repeat surfacing within
    /// the same session.
    public private(set) var didJustReachAllTiers: Bool
    /// Once the kid has reached all four tiers in the session, the cue
    /// has been surfaced (or explicitly acknowledged) — don't re-emit it.
    public private(set) var hasAcknowledgedAllTiers: Bool

    public init() {
        self.visitedTiers = []
        self.didJustReachAllTiers = false
        self.hasAcknowledgedAllTiers = false
    }

    /// Record a tier visit. Returns true if THIS visit was the one that
    /// completed the full set (the caller can branch immediately on the
    /// return value instead of reading `didJustReachAllTiers`).
    @discardableResult
    public mutating func record(visit tier: ZoomTier) -> Bool {
        guard !hasAcknowledgedAllTiers else {
            // Once acknowledged, never re-trigger within this session.
            return false
        }
        let inserted = visitedTiers.insert(tier).inserted
        let nowComplete = visitedTiers.count == ZoomTier.allCases.count
        if inserted, nowComplete {
            didJustReachAllTiers = true
            return true
        }
        return false
    }

    /// Mark the all-tiers reward as consumed so subsequent `record(visit:)`
    /// calls don't re-trigger it within the same session.
    public mutating func acknowledgeAllTiersReached() {
        hasAcknowledgedAllTiers = true
        didJustReachAllTiers = false
    }

    /// Convenience for tests + Settings debug surfaces.
    public mutating func reset() {
        self = EasterEggDetector()
    }

    // MARK: - Rare microbe selection

    /// Deterministic per-session selection of a "curious-explorer" microbe
    /// slug from the catalog. Uses the same splitmix64 mixer family as
    /// `VariableRewardSelector` for tight cohesion + zero new dependency
    /// surface. Returns `nil` when the catalog is empty (test fixture
    /// safety).
    public static func curiousExplorerMicrobe(
        forSessionCount sessionCount: Int,
        microbeSlugs: [String]
    ) -> String? {
        guard !microbeSlugs.isEmpty else { return nil }
        // Salt distinct from `VariableRewardSelector.appSalt` so the
        // easter-egg pick decorrelates from the variable-reward pick on
        // the same session.
        var z = UInt64(0xE45E_5E66_C051_FEED) &+ UInt64(sessionCount) &* 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z &>> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z &>> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z &>> 31
        let index = Int(z % UInt64(microbeSlugs.count))
        return microbeSlugs[index]
    }
}
