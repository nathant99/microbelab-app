import Foundation

/// Variable-reward surface per `Docs/FEATURE_PLAN.md` § Engagement Foundation
/// → "~1 in 5 sessions: rare microbe sighting / hidden codex entry / special
/// Vee reaction".
///
/// Engagement literature (Skinner / Schultz) treats variable-ratio reward as
/// the most engagement-positive reinforcement schedule. The portfolio's COPPA
/// + trauma-informed posture rejects gambling-style randomness, so this
/// selector is **deterministic per session** — same kid + same session count
/// always produces the same reward. The visible cadence still reads as ~1 in
/// 5 because the kid doesn't see the source.
public nonisolated enum VariableReward: Sendable, Equatable {
    /// Highlight a specific microbe (passed as a slug from the catalog) as
    /// "rare today" in the microscope cue.
    case rareMicrobeSighting(slug: String)
    /// Trigger a softer, more personal Vee voice line outside the usual
    /// fallback rotation.
    case specialMentorMoment
}

/// Pure deterministic selector. Lives in `Services` so callers can hand it a
/// session count + a sorted slug list and get a reproducible result without
/// touching the SwiftUI surface.
public nonisolated struct VariableRewardSelector: Sendable {
    /// Per-app salt so two MicrobeLab installs feel the same but a different
    /// portfolio app's selector (when it lifts this) gets uncorrelated draws.
    public static let appSalt: UInt64 = 0xABC1_B005_BABE_0001

    /// ~1 in 5 sessions surface a reward — the literature's recommended
    /// cadence for variable-ratio reinforcement without being either too
    /// sparse (kid stops anticipating) or too dense (kid stops noticing).
    public static let rewardFrequency: Int = 5

    /// Returns a reward for the given session count, or `nil` when the
    /// session lands outside the variable-reward cadence.
    public static func select(
        forSessionCount sessionCount: Int,
        microbeSlugs: [String],
        salt: UInt64 = Self.appSalt
    ) -> VariableReward? {
        guard sessionCount > 0 else { return nil }

        // splitmix64-style mixer of (salt, sessionCount) — same input always
        // produces the same output; adjacent inputs decorrelate cleanly.
        var z = salt &+ UInt64(sessionCount) &* 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z &>> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z &>> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z &>> 31

        guard z % UInt64(rewardFrequency) == 0 else { return nil }

        // Kind selection: even mixer-hi bit = microbe sighting, odd = mentor.
        let pickMicrobe = (z &>> 32) & 1 == 0
        if pickMicrobe, !microbeSlugs.isEmpty {
            let index = Int(z % UInt64(microbeSlugs.count))
            return .rareMicrobeSighting(slug: microbeSlugs[index])
        }
        return .specialMentorMoment
    }
}
