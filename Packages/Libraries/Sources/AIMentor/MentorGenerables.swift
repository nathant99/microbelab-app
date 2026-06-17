import Foundation
import FoundationModels

/// Single-sentence Socratic prompt + curriculum-mapped factoid surfaced when
/// the kid meets a microbe for the first time in the codex.
///
/// Property order is intentional per `.claude/rules/foundationmodels.md` — the
/// model writes `socraticPrompt` first so the factual body can reference the
/// question without re-deriving it.
@Generable
public struct MicrobeFact: Codable, Sendable, Equatable {
    @Guide(description: "Single-sentence open-ended Socratic question about the microbe, age-9-14 register.")
    public let socraticPrompt: String
    @Guide(description: "Two-sentence curriculum fact, hedged language only — never absolute claims.")
    public let factBody: String

    public init(socraticPrompt: String, factBody: String) {
        self.socraticPrompt = socraticPrompt
        self.factBody = factBody
    }
}

/// Mentor reaction to a microscope tier transition. Surfaced in the speech
/// bubble when the kid pinches through a magnification boundary.
@Generable
public struct ZoomCue: Codable, Sendable, Equatable {
    @Guide(description: "Warm reaction to the new tier in one sentence, no exclamation points.")
    public let reaction: String
    @Guide(description: "What to look for at this magnification, single phrase.")
    public let lookForHint: String

    public init(reaction: String, lookForHint: String) {
        self.reaction = reaction
        self.lookForHint = lookForHint
    }
}

/// Ecology-prompt the mentor surfaces when the kid changes feeding mode or
/// applies an antibiotic — frames the change as a question the kid can test.
@Generable
public struct EcologyHypothesis: Codable, Sendable, Equatable {
    @Guide(description: "Observation cue framed as an open-ended question.")
    public let observation: String
    @Guide(description: "One testable prediction the kid can verify by tweaking the simulator.")
    public let hypothesis: String

    public init(observation: String, hypothesis: String) {
        self.observation = observation
        self.hypothesis = hypothesis
    }
}

/// Adaptive-immunity scenarios the mentor scaffolds across the
/// `BCellAntibodyMatchScene` arc. Per CLAUDE.md trauma-informed posture +
/// `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed Design Posture: framed as
/// protection + recognition, never as warfare. The three cases cover the
/// canonical pedagogy beats the mentor needs to surface during the
/// adaptive-immunity Phase 2 arc.
public nonisolated enum AdaptiveImmuneScenario: String, Codable, Sendable, CaseIterable {
    /// First exposure — the body meets a new shape it hasn't catalogued.
    case firstEncounter
    /// Antibody-to-antigen match — the kid lines up a complementary shape.
    case matchedShape
    /// Re-exposure — memory cells recognize the shape faster than first time.
    case recallFromMemory
}

/// Mentor reaction surfaced during the adaptive-immunity Phase 2 surface
/// (B-cell antibody-matching minigame + memory-cell recognition arc).
///
/// Property order matters per `.claude/rules/foundationmodels.md` — the
/// LLM writes `observation` first so the testable `memoryHypothesis` can
/// reference the same shape-matching language without re-deriving it.
///
/// Trauma-informed register (per `Docs/TECHNICAL_DESIGN.md`):
/// - Frames immune response as RECOGNITION (the body's library of shapes),
///   not warfare (no "destroy" / "attack" / "kill" framing).
/// - The cast verb is "match" or "remember", not "fight".
/// - Memory framing is curiosity-positive ("the body keeps a note") not
///   threat-anxiety ("the body must be ready").
///
/// Authored fallback content (`VeeMentor.fallbackAdaptiveImmuneHypothesis`)
/// is always available so the mentor surfaces calmly even when
/// FoundationModels is unavailable or paused.
@Generable
public struct AdaptiveImmuneHypothesis: Codable, Sendable, Equatable {
    @Guide(description: "Open-ended observation framed around shape-matching recognition (not warfare). Age 9-14 register, hedging language only.")
    public let observation: String
    @Guide(description: "One testable prediction about memory cells or antibody recognition the kid can verify in the simulator. Trauma-safe: never frames re-exposure as threat.")
    public let memoryHypothesis: String

    public init(observation: String, memoryHypothesis: String) {
        self.observation = observation
        self.memoryHypothesis = memoryHypothesis
    }
}

/// Public-health scenarios the mentor scaffolds across the Phase 3
/// disease-story arcs (`Models/DiseaseStoryArc`). The four cases align
/// 1:1 with the canonical arcs scaffolded in PR #141.
///
/// Per CLAUDE.md trauma-informed posture + `.claude/rules/trauma-informed-content.md`:
/// the public-health pedagogy applies the SAMHSA register — handwashing
/// is care (not moral test); vaccines are a library primer (not warfare);
/// antibiotic recovery is patience (not failure); community response is
/// helpers (not panic).
public nonisolated enum PublicHealthScenario: String, Codable, Sendable, CaseIterable {
    /// Handwashing surface — gentle care for the microbiome neighborhood,
    /// NOT a moral test or shame surface for missed washes.
    case handwashing
    /// Vaccine-priming surface — the B-cell library learning a new shape
    /// before it meets the live antigen, NEVER warfare framing.
    case vaccinePriming
    /// Antibiotic stewardship surface — the microbiome recovers slowly
    /// after antibiotic care. Slow IS wise; recovery IS the lesson.
    case antibioticStewardship
    /// Outbreak recovery surface — community helpers framing per
    /// SAMHSA TIP 57 (validate-then-inform / hold-space / refer-up).
    /// Never panic / crisis / threat framing.
    case outbreakRecovery
}

/// Mentor reaction surfaced during the Phase 3 disease-story arc surfaces.
///
/// Property order matters per `.claude/rules/foundationmodels.md` — the
/// LLM writes `observation` first so the testable `healthHypothesis` can
/// reference the same public-health language without re-deriving it.
///
/// Trauma-informed register (per `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed
/// Design Posture + ADR-016 SAMHSA TIP 57 framing):
/// - Handwashing framed as CARE (not moral test, not shame).
/// - Vaccines framed as the body's LIBRARY learning a new shape (not warfare).
/// - Antibiotic recovery framed as PATIENCE and slow rebuilding (not failure).
/// - Outbreak recovery framed as COMMUNITY HELPING each other (not panic /
///   threat / crisis).
///
/// Authored fallback content (`VeeMentor.fallbackPublicHealthHypothesis`)
/// is always available so the mentor surfaces calmly even when
/// FoundationModels is unavailable or paused.
@Generable
public struct PublicHealthHypothesis: Codable, Sendable, Equatable {
    @Guide(description: "Open-ended observation framed around care + curiosity + community (never warfare or threat). Age 9-14 register, hedging language only.")
    public let observation: String
    @Guide(description: "One testable prediction about how the microbiome or community responds, framed as ecology + recovery (never blame / shame / panic). Trauma-safe per SAMHSA TIP 57.")
    public let healthHypothesis: String

    public init(observation: String, healthHypothesis: String) {
        self.observation = observation
        self.healthHypothesis = healthHypothesis
    }
}
