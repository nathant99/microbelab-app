import Foundation
import ForgeAI

/// Pure-value registry of the 6 MicrobeLab DN-S cast `CastVoiceProfile`s,
/// indexed by `MicrobeCharacter.slug`.
///
/// Closes `Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` (Round 397
/// #820 — labsmith DN-S Integration Phase 1D portfolio rollout) by giving
/// `VeeMentor` an opt-in seam to dispatch utterances through the per-cast
/// `CastDialog` API at ForgeKit 0.97.0+.
///
/// The registry is a `nonisolated public struct` (Sendable / Codable safe) —
/// `CastDialog` is an `actor` and lives on the consumer side. Building the
/// registry on first launch + handing each `CastVoiceProfile` to
/// `CastDialog.register(_:)` is the canonical wiring; this type just owns
/// the canonical list + slug lookups so the wiring stays declarative.
///
/// Per the handoff's "Pilot-derived learnings" § 1 (prompt-budget
/// calibration), the 6 MicrobeLab profiles total 1614 chapter words across
/// 6 cast members — well under the 12-profile / iPad Mini 2026 perf ceiling
/// from the QuillSpell + ProofQuest + GambitTales 3-app pilot. No per-app
/// prompt-budget tuning required for MicrobeLab.
///
/// Per the handoff's `trauma-gating: NONE` + `moderation-sensitivity: .normal`,
/// every profile ships `reviewerGated: false`. `CastDialog.register(_:signoff:)`
/// accepts each profile without a `ReviewerSignoff` token.
public nonisolated struct CastVoiceRegistry: Sendable {

    /// All 6 canonical profiles in chapter order
    /// (Lacto → Yeast → Photo → Net → Spore → Guard).
    public let profiles: [CastVoiceProfile]

    /// Slug → `CastVoiceProfile` lookup for O(1) dispatch from `VeeMentor`
    /// call sites that already carry a `MicrobeCharacter.slug`.
    public let bySlug: [String: CastVoiceProfile]

    /// Build the canonical registry. The default value loads the 6 profiles
    /// authored at `MicrobeCastVoiceProfiles.allProfiles()`; tests may
    /// substitute a custom list to exercise the wiring without the full
    /// 6-member catalog.
    public init(profiles: [CastVoiceProfile] = MicrobeCastVoiceProfiles.allProfiles()) {
        self.profiles = profiles
        var byID: [String: CastVoiceProfile] = [:]
        byID.reserveCapacity(profiles.count)
        for profile in profiles {
            byID[profile.id] = profile
        }
        self.bySlug = byID
    }

    /// Lookup a `CastVoiceProfile` by slug. Returns `nil` when the slug
    /// isn't in the registered set — `VeeMentor` callers fall back to the
    /// existing static `voiceLine(for:rotation:)` accessor.
    public func profile(forSlug slug: String) -> CastVoiceProfile? {
        bySlug[slug]
    }

    /// The set of registered cast slugs. Useful for `CastDialog.register`
    /// loops + parameterized tests that assert per-slug presence.
    public var registeredSlugs: Set<String> {
        Set(bySlug.keys)
    }

    /// The shared catchphrase-pool size invariant — every profile MUST ship
    /// `catchphrases.count >= 3` (enforced at `CastVoiceProfile.init` via
    /// `precondition`). Exposed as a derived property so tests can pin the
    /// invariant explicitly without re-deriving from the profile array.
    public var minimumCatchphraseCount: Int {
        profiles.map(\.catchphrases.count).min() ?? 0
    }

    /// Register every profile against the supplied `CastDialog` actor in a
    /// single async hop. Convenience wrapper around the per-profile
    /// `register(_:)` call site `VeeMentor` would otherwise duplicate. None
    /// of the MicrobeLab profiles is `reviewerGated`, so no `ReviewerSignoff`
    /// is required.
    ///
    /// Returns the registered profile count after the wiring completes.
    @discardableResult
    public func register(into castDialog: CastDialog) async throws -> Int {
        for profile in profiles {
            try await castDialog.register(profile)
        }
        return await castDialog.registeredCount
    }
}
