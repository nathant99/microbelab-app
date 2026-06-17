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

/// Vaccine-mechanism step the mentor scaffolds during the Phase 3 vaccine
/// mini-explainer (`Models/VaccineExplainerStep`). The four cases align 1:1
/// with the canonical 4-step pedagogy spine (introduction → antibodyPriming
/// → memoryFormation → boosterRationale) so the mentor surface can refresh
/// a per-step Socratic prompt when the kid steps through the explainer's
/// segmented picker.
///
/// Per `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed Design Posture: the
/// vaccine surface is the body's LIBRARY learning a new shape — never a
/// warfare / battle / weapon register.
public nonisolated enum VaccineMechanismScenario: String, Codable, Sendable, CaseIterable {
    /// Pairs with `VaccineExplainerStep.introduction` — gentle framing of
    /// vaccines as a kind helper, not a fear hook.
    case introduction
    /// Pairs with `VaccineExplainerStep.antibodyPriming` — the B-cell
    /// library practices matching a new shape before the live antigen
    /// arrives. Inherits the Phase 2 adaptive-immunity register.
    case antibodyPriming
    /// Pairs with `VaccineExplainerStep.memoryFormation` — the body keeps
    /// a note of the matched shape so it recognizes it faster next time.
    case memoryFormation
    /// Pairs with `VaccineExplainerStep.boosterRationale` — why a second
    /// dose helps the library remember more steadily. Framed as care +
    /// patience, never failure of the first dose.
    case boosterRationale
}

/// Mentor cue surfaced during the Phase 3 vaccine mini-explainer view
/// (`AppFeature/Engagement/VaccineExplainerView`).
///
/// Property order matters per `.claude/rules/foundationmodels.md` — the
/// LLM writes `observation` first so the testable `librariesHypothesis`
/// can reference the same shape-matching language without re-deriving it.
///
/// Trauma-informed register (per `Docs/TECHNICAL_DESIGN.md` + ADR-016):
/// - Vaccines are the body's library learning a shape ahead of meeting
///   it live — NEVER warfare / battle / weapon framing.
/// - The B-cell library is curious + patient, not anxious or fearful.
/// - Booster doses are care + reinforcement, not corrections of failure.
///
/// Authored fallback content (`VeeMentor.fallbackVaccineMechanismCue`)
/// is always available so the mentor surfaces calmly even when
/// FoundationModels is unavailable or paused.
@Generable
public struct VaccineMechanismCue: Codable, Sendable, Equatable {
    @Guide(description: "Open-ended observation question framed around the body's library learning a shape (never warfare). Age 9-14 register, hedging language only.")
    public let observation: String
    @Guide(description: "One testable prediction about how the antibody library or memory cells respond to vaccine-priming, framed as care + curiosity. Trauma-safe: never frames re-exposure as threat.")
    public let librariesHypothesis: String

    public init(observation: String, librariesHypothesis: String) {
        self.observation = observation
        self.librariesHypothesis = librariesHypothesis
    }
}

/// Mentor reflection scaffolded during the Phase 3 historical context
/// cards view (`AppFeature/Engagement/HistoricalContextCardsView`). The four
/// cases align 1:1 with `Models/HistoricalContextFigure` (pasteur / koch /
/// salk / marshall).
///
/// Per CQ CONTENT_STYLE_GUIDE.md § 4.5 anti-credentialism gate + ADR-016:
/// figures are framed as PATIENT OBSERVERS taking small careful steps —
/// never hero-myth, never mortality-anxiety, never warfare lexicon. The
/// pedagogy register foregrounds the kid scientist way of being (long
/// noticing + careful experiment) so kids see themselves in the work.
public nonisolated enum HistoricalContextScenario: String, Codable, Sendable, CaseIterable {
    /// Pairs with `HistoricalContextFigure.pasteur` — patient experimental
    /// notebook register, NOT the rabid-dog drama. Bridges to labsmith via
    /// `crossPortfolioBridges`.
    case pasteur
    /// Pairs with `HistoricalContextFigure.koch` — pattern-noticing
    /// methodology spine, NOT mortality-counting of TB / cholera.
    case koch
    /// Pairs with `HistoricalContextFigure.salk` — community made polio
    /// rare through care; public-health wonder, never panic-recall.
    case salk
    /// Pairs with `HistoricalContextFigure.marshall` — long noticing +
    /// small careful experiments overturned consensus; bridges to the
    /// Phase 2 Pylo cast member + curiosityquest kid-scientist register.
    case marshall
}

/// Mentor reflection surfaced during the Phase 3 historical context cards
/// view. Pairs each canonical figure with a reflection the kid can carry
/// forward.
///
/// Property order matters per `.claude/rules/foundationmodels.md` — the
/// LLM writes `noticing` first so the testable `kidScientistTakeaway` can
/// reference the same patient-observation language without re-deriving it.
///
/// Trauma-informed register (per `Docs/TECHNICAL_DESIGN.md` + ADR-016 +
/// CQ CONTENT_STYLE_GUIDE.md § 4.5):
/// - Figures framed as PATIENT OBSERVERS, never as hero-myth.
/// - Anti-credentialism: the kid can do this kind of work too.
/// - No mortality framing on disease lexicon (Koch's TB, Salk's polio,
///   Marshall's stomach-ulcer) — the work surfaces as pattern noticing.
/// - No warfare / battle / weapon lexicon.
///
/// Authored fallback content (`VeeMentor.fallbackHistoricalContextReflection`)
/// is always available so the mentor surfaces calmly even when
/// FoundationModels is unavailable or paused.
@Generable
public struct HistoricalContextReflection: Codable, Sendable, Equatable {
    @Guide(description: "Open-ended question naming what the figure noticed across long careful observation (never hero-myth, never mortality framing). Age 9-14 register, hedging language only.")
    public let noticing: String
    @Guide(description: "A kid-scientist takeaway the kid can carry into their own observation today, framed as small careful steps. Anti-credentialism: the kid can do this kind of work too.")
    public let kidScientistTakeaway: String

    public init(noticing: String, kidScientistTakeaway: String) {
        self.noticing = noticing
        self.kidScientistTakeaway = kidScientistTakeaway
    }
}

/// Tour stop the mentor scaffolds during the Phase 4 global-microbiome tour
/// (`Models/GlobalMicrobiomeTourStop`). The four cases align 1:1 with the
/// canonical tour stops in the load-bearing wonder-forward order:
/// Yellowstone hot spring → deep-sea vent → human gut → soil underground.
///
/// Per `Docs/TECHNICAL_DESIGN.md` § Phase 4 + `.claude/rules/distributed-narrative.md`
/// § cultural-sensitivity gates: the Yellowstone surface MUST credit
/// Indigenous TEK (Crow, Eastern Shoshone, Northern Arapaho, Bannock,
/// Blackfeet, Confederated Salish-Kootenai); the deep-sea vent surface
/// frames extremophile adaptation as wonder + adaptation pride; the gut
/// surface bridges back to Phase 1 / 2 ecology math at world scale; the
/// soil surface bridges to bioforge/ecosphere as a thriving system NEVER
/// "dirt".
public nonisolated enum GlobalMicrobiomeTourScenario: String, Codable, Sendable, CaseIterable {
    /// Pairs with `GlobalMicrobiomeTourStop.yellowstoneHotSpring` —
    /// thermophilic ecosystem + Indigenous TEK credit. Featured cast:
    /// Crenarch + Therm.
    case yellowstoneHotSpring
    /// Pairs with `GlobalMicrobiomeTourStop.deepSeaVent` — chemosynthesis +
    /// extremophile adaptation. The deep sea is a thriving system, NEVER
    /// a dark scary place. Featured cast: Crenarch + Baro.
    case deepSeaVent
    /// Pairs with `GlobalMicrobiomeTourStop.humanGut` — host-microbiome
    /// mutualism reviewed at world scale. Bridges back to Phase 1 / 2
    /// ecology scenes. Featured cast: Lacto + Akker + Bifido.
    case humanGut
    /// Pairs with `GlobalMicrobiomeTourStop.soilUnderground` — decomposer
    /// ecology + nitrogen fixation. Cross-portfolio bridge to bioforge /
    /// ecosphere. Featured cast: Loam + Nodu + Halo.
    case soilUnderground
}

/// Mentor reaction surfaced during the Phase 4 global-microbiome tour view
/// (`AppFeature/GlobalMicrobiomeTourView`).
///
/// Property order matters per `.claude/rules/foundationmodels.md` — the
/// LLM writes `wonderObservation` first so the testable
/// `connectionToCast` can reference the same wonder language without re-
/// deriving it.
///
/// Trauma-informed + cultural-respect register (per
/// `Docs/TECHNICAL_DESIGN.md` + `.claude/rules/distributed-narrative.md`):
/// - Wonder-forward framing — extremophiles are pride + adaptation, never
///   "scary" / "deadly" / "horror" / "doom".
/// - Yellowstone surface MUST surface Indigenous TEK credit.
/// - Deep-sea surface frames the vent community as a thriving system.
/// - Gut surface bridges to Phase 1 / 2 ecology math the kid already knows.
/// - Soil surface frames soil as a thriving system NEVER "dirt".
///
/// Authored fallback content (`VeeMentor.fallbackGlobalMicrobiomeTourCue`)
/// is always available so the mentor surfaces calmly even when
/// FoundationModels is unavailable or paused.
@Generable
public struct GlobalMicrobiomeTourCue: Codable, Sendable, Equatable {
    @Guide(description: "Open-ended wonder-observation question framed around adaptation + thriving (never warfare or fear). Age 9-14 register, hedging language only.")
    public let wonderObservation: String
    @Guide(description: "One connection back to a named cast microbe at this stop, framed as recognition + ecology bridge (the same ecology math the kid already knows applies here too). Trauma-safe: never frames the cast as scary or threatening.")
    public let connectionToCast: String

    public init(wonderObservation: String, connectionToCast: String) {
        self.wonderObservation = wonderObservation
        self.connectionToCast = connectionToCast
    }
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
