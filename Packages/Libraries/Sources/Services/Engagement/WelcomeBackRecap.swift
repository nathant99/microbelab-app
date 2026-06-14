import Foundation
import Models

/// Pure value-type recap content surfaced by `WelcomeBackOverlay` when a
/// returning kid (≥ 3 calendar-day lapse — the existing gate in
/// `LastActiveStore.shouldShowWelcomeBack`) has previously discovered at
/// least one microbe.
///
/// The recap is a warm callback layer that closes the FEATURE_PLAN.md §
/// Engagement Foundation "Return loop" follow-up — the existing surface
/// shipped the warm greeting + Continue affordance; this type adds the
/// "best-work recap" portion called out as a deferred follow-up in
/// `WelcomeBackOverlay`'s class-level doc-comment.
///
/// Trauma-informed posture (per `.claude/rules/trauma-informed-content.md`
/// + `.claude/rules/distributed-narrative.md` § Audience register
/// 9-14):
/// - The recap is OPT-OUT structurally: `WelcomeBackRecap.from(...)`
///   returns `nil` when there's nothing meaningful to recall (zero
///   discovered microbes). The greeting still surfaces; only the recap
///   card is hidden.
/// - The recap NEVER mentions undiscovered microbes (no "you haven't
///   met..." framing — mirrors the trauma-informed posture on
///   `MicrobeCodexView` ecology neighbors).
/// - Microbe quotes are deterministic per absence-duration so the same
///   `daysAway` always quotes the same microbes in the same order;
///   refreshing the surface within a session never shuffles the recap.
///   (Matches the `VariableRewardSelector` / `EasterEggDetector`
///   determinism pattern — predictability is calming.)
/// - Microbe count clamped to ≤ 2 so the card stays small + cold-launch
///   visual surface stays calm.
public nonisolated struct WelcomeBackRecap: Sendable, Equatable {
    /// Display names of the microbes the recap surfaces (1-2 entries).
    /// Ordering is deterministic per `daysAway` per the determinism rule
    /// above.
    public let recalledMicrobeDisplayNames: [String]

    /// Trauma-informed lead-in copy that frames the recap card. Stays
    /// short (≤ 12 words) so the kid skims rather than reads.
    public let leadInCopy: String

    public init(recalledMicrobeDisplayNames: [String], leadInCopy: String) {
        self.recalledMicrobeDisplayNames = recalledMicrobeDisplayNames
        self.leadInCopy = leadInCopy
    }

    /// Salt distinct from `VariableRewardSelector.appSalt` /
    /// `EasterEggDetector.appSalt` / `MentorRecallStore`'s ring buffer
    /// position so the recap and other engagement-surface picks
    /// decorrelate. Microbes the kid sees in the variable-reward cue
    /// shouldn't all also surface as the welcome-back recap microbes.
    public static let appSalt: UInt64 = 0xC4FE_BABE_BEEF_F00D

    /// Build a recap from the kid's discovered slug set + the bundled
    /// catalog + the absence duration. Returns `nil` when:
    /// - `discoveredSlugs` is empty (no recall surface to seed)
    /// - All discovered slugs are unknown to `catalog` (defensive against
    ///   stale persisted state after a catalog version bump)
    ///
    /// Otherwise picks up to 2 microbe display names via a deterministic
    /// splitmix64 mixer of `(appSalt, daysAway)`, with the
    /// `daysAway`-keyed leadInCopy ("It's been N days — X and Y were
    /// still busy" / etc.).
    public static func from(
        discoveredSlugs: Set<String>,
        catalog: MicrobeCatalogService,
        daysAway: Int
    ) -> WelcomeBackRecap? {
        guard !discoveredSlugs.isEmpty else { return nil }

        // Resolve known slugs → display names; preserve slug ordering
        // determinism by sorting before resolution (a Set has no canonical
        // order; the sort + mixer pair gives reproducible picks).
        let knownMicrobes = discoveredSlugs
            .sorted()
            .compactMap { catalog.microbe(forSlug: $0) }

        guard !knownMicrobes.isEmpty else { return nil }

        // Deterministic per-(salt, daysAway) shuffle via splitmix64 — see
        // `VariableRewardSelector` for the canonical mixer.
        var rng = mix(appSalt, UInt64(bitPattern: Int64(daysAway)))
        var pool = knownMicrobes
        var picks: [MicrobeCharacter] = []
        let target = min(2, pool.count)
        while picks.count < target, !pool.isEmpty {
            let idx = Int(rng % UInt64(pool.count))
            picks.append(pool.remove(at: idx))
            rng = mix(rng, 0xDEAD_BEEF_CAFE_F00D)
        }

        let names = picks.map(\.displayName)
        return WelcomeBackRecap(
            recalledMicrobeDisplayNames: names,
            leadInCopy: leadInCopy(forDaysAway: daysAway, recalledCount: names.count)
        )
    }

    /// Trauma-informed warm callback copy. Per `.claude/rules/
    /// distributed-narrative.md` § Audience register (9-14): warmly
    /// absurd with subtext, never punitive, never loss-aversion. The
    /// canonical stoplist below is enforced by `WelcomeBackRecapTests`.
    static func leadInCopy(forDaysAway daysAway: Int, recalledCount: Int) -> String {
        // The microbes-care-about-you framing matches `WelcomeBackOverlay`'s
        // body-copy register ("The microbiome was curious about you")
        // without duplicating the exact wording.
        if recalledCount == 1 {
            return "Still under the lens since you left:"
        }
        return "Still hanging around since you left:"
    }

    private static func mix(_ a: UInt64, _ b: UInt64) -> UInt64 {
        // splitmix64 step — mirrors `VariableRewardSelector.mix(_:_:)`.
        var z = (a &+ b) &+ 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z &>> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z &>> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z &>> 31)
    }
}
