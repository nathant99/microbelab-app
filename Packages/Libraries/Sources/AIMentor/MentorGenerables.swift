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
