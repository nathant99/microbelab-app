import Foundation
import Models

/// Stub for the Cilia (formerly Vee) Socratic mentor.
///
/// Per `Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` the
/// mentor name was renamed to Cilia to resolve the Dr. Quark hard collision
/// with AdventureHub Wave 27. The class name stays `VeeMentor` to match the
/// original spec; the player-facing display string lives in `displayName`.
///
/// Real FoundationModels wiring (`@Generable MicrobeFact`, `ZoomCue`,
/// `EcologyHypothesis`) lands in a follow-up PR per FEATURE_PLAN. This stub
/// reserves the public surface so the AppFeature target can wire mentor
/// events without waiting on FoundationModels availability.
@MainActor
public final class VeeMentor {
    public static let displayName = "Cilia"

    /// Static curriculum-guarded fallback for the catchphrase event.
    /// Real implementation pulls from the bundled cast voice-register cards.
    public let microbes: [MicrobeCharacter]

    public init(microbes: [MicrobeCharacter]) {
        self.microbes = microbes
    }

    /// Returns the static catchphrase for the named microbe — no AI call.
    /// Used for first-meet events; the AI surface activates on follow-up
    /// Socratic prompts in a later PR.
    public func catchphrase(for slug: String) -> String? {
        microbes.first { $0.slug == slug }?.catchphrase
    }

    /// Returns the curriculum-mapped fact card for the named microbe.
    /// Static content per `.claude/rules/ai-content.md` — never AI-generated.
    public func factCard(for slug: String) -> String? {
        microbes.first { $0.slug == slug }?.factCard
    }
}
