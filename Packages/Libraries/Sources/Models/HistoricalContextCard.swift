import Foundation

/// One of the four canonical Phase 3 historical context cards scoped in
/// `Docs/FEATURE_PLAN.md` § Phase 3 *"Bundle historical context cards
/// (Pasteur / Koch / Salk / portfolio cast)"*.
///
/// **Important**: prose content for these cards is NOT authored in-app.
/// Every card ships with `authoring == .placeholder` until external reviewer
/// signs off per `.claude/rules/trauma-informed-content.md` § historical
/// figure framing + ADR-016. The catalog ships the metadata + curricular
/// hooks + cross-portfolio bridges so the structural scaffold can be wired
/// (`ProgressionService.disease-story-immune` gate from PR #137,
/// `ParentalConsentService.diseaseStoryArcs` opt-in) without committing to
/// prose that has not been reviewed.
public nonisolated enum HistoricalContextFigure: String, Codable, Sendable, CaseIterable, Identifiable {
    /// Louis Pasteur (1822-1895) — germ theory + early vaccination. Bridges
    /// curricularly to the vaccinePriming disease-story arc (PR #141). Frames
    /// the experimental notebook side of his work, NEVER the
    /// hero-myth lexicon (per CQ CONTENT_STYLE_GUIDE.md § 4.5
    /// anti-credentialism gate). Trauma-informed: foregrounds his patient
    /// observation + careful experimentation, not the rabid-dog-vaccination
    /// drama that sometimes leads in popular framings.
    case pasteur

    /// Robert Koch (1843-1910) — Koch's postulates (specific-pathogen logic).
    /// Bridges to all 4 disease-story arcs as the methodology spine. Frames
    /// the kid scientist register: how to know which microbe causes which
    /// disease. NEVER mortality-framed (his TB + cholera work is framed as
    /// pattern-noticing, not death-counting).
    case koch

    /// Jonas Salk (1914-1995) — polio vaccine + public-health success.
    /// Bridges to vaccinePriming + outbreakRecovery arcs. Frames the public-
    /// health-wonder side: a community made polio rare through care.
    /// Trauma-safe COVID register inherits from the app's overarching
    /// posture — recent pandemic experience handled gently in any prose.
    case salk

    /// Barry Marshall (1951-present) — H. pylori self-inoculation +
    /// stomach-ulcer ecology revision. Bridges to the Phase 2 Pylo cast
    /// member (PR #119). Frames his work as patient observation paying off,
    /// NEVER dangerous-bravado lexicon. The 1980s consensus-overturning
    /// story is a model of the kid scientist register: long noticing + small
    /// careful experiments.
    case marshall

    public var id: String { rawValue }

    /// Kid-readable title; safe to surface in menus while the body content
    /// is `.placeholder` because the title alone doesn't promise anything
    /// the kid can't already infer from the menu chrome.
    public var displayTitle: String {
        switch self {
        case .pasteur:  return "Louis Pasteur"
        case .koch:     return "Robert Koch"
        case .salk:     return "Jonas Salk"
        case .marshall: return "Barry Marshall"
        }
    }

    /// Approximate lifespan range. String form to support living scientists.
    public var era: String {
        switch self {
        case .pasteur:  return "1822-1895"
        case .koch:     return "1843-1910"
        case .salk:     return "1914-1995"
        case .marshall: return "1951-present"
        }
    }

    /// Stable curricular hook. The contribution descriptor surfaces in the
    /// card metadata so the parent surface can render "What this card
    /// teaches" without re-deriving from prose.
    public var contribution: String {
        switch self {
        case .pasteur:  return "germ theory + early vaccination"
        case .koch:     return "specific-pathogen postulates"
        case .salk:     return "polio vaccine + public-health success"
        case .marshall: return "H. pylori + ecology of stomach ulcers"
        }
    }

    /// 24-microbe catalog slugs (PR #119 + extremophile pack PR #151) the
    /// historical card cross-references. The view layer renders these as
    /// chips that tap-dispatch to the codex card. Empty arrays are valid:
    /// some figures (Pasteur / Salk) don't anchor on a specific microbe in
    /// the bundled catalog.
    public var relevantMicrobeSlugs: [String] {
        switch self {
        case .pasteur:  return []                // germ-theory + rabies — no single catalog slug anchor
        case .koch:     return []                // TB + cholera — not in the kid-cast catalog
        case .salk:     return []                // polio — not in the catalog
        case .marshall: return ["pylo"]          // H. pylori IS in the Phase 2 cast (PR #119)
        }
    }

    /// Cross-portfolio app bridges — slugs reference sibling apps with
    /// curricular overlap per `.claude/rules/distributed-narrative.md`
    /// § "Cluster coherence" failure-mode test. The view layer renders these
    /// as small "Related" chips that link to the portfolio app page on
    /// spark-anvil-site (deep link / web). Empty arrays valid.
    public var crossPortfolioBridges: [String] {
        switch self {
        case .pasteur:  return ["labsmith"]      // Pasteur's experimental notebook ↔ labsmith's notebook register
        case .koch:     return []
        case .salk:     return []
        case .marshall: return ["curiosityquest"] // Patient-observation kid scientist register
        }
    }

    /// Which gate this card lives behind. All four ride the
    /// `disease-story-immune` gate from `ProgressionService` (PR #137 — 5
    /// sessions + 3 immune runs). Historical context cards build on the
    /// adaptive-immunity surface so the gate-routing matches the immune
    /// pedagogy beat, not the broader microbiome beat.
    public var gateID: String {
        "disease-story-immune"
    }
}

/// Per-card authoring state. The `.placeholder` state is load-bearing: the
/// catalog can ship all four cards structurally while keeping prose content
/// reviewer-blocked. Consuming views MUST gate rendering on
/// `authoring == .reviewerSignedOff` so the kid never sees draft prose.
public nonisolated enum HistoricalContextAuthoring: String, Codable, Sendable, CaseIterable {
    /// Structural placeholder — title + era + contribution + cross-references
    /// only. No prose. The menu surfaces a "Coming soon" affordance instead
    /// of the card body. This is the default for every card in Phase 3
    /// rounds until reviewer-signoff lands.
    case placeholder

    /// Draft prose authored but NOT yet reviewer-signed-off. Visible to the
    /// implementing session for review; views still surface the "Coming
    /// soon" affordance until `.reviewerSignedOff`.
    case draftAwaitingReview

    /// Reviewer-signed-off prose, kid-safe to render. Per ADR-016 + CQ
    /// CONTENT_STYLE_GUIDE.md § 4.5 anti-credentialism gate, the reviewer
    /// must pass on the hero-myth-vs-patient-observation framing.
    case reviewerSignedOff
}

/// A scaffolded historical context card record. Carries metadata + cross-
/// references + gate keys + authoring state. Prose body lives in the
/// consuming view layer (when authored) — this record stays minimal so the
/// catalog can grow without inflating value-type surfaces. Mirrors the
/// `DiseaseStoryArcRecord` (PR #141) + `GlobalMicrobiomeTourStopRecord`
/// (Option 5) shape.
public nonisolated struct HistoricalContextCardRecord: Codable, Sendable, Equatable, Identifiable {
    public let figure: HistoricalContextFigure
    public let authoring: HistoricalContextAuthoring

    public var id: String { figure.rawValue }
    public var displayTitle: String { figure.displayTitle }
    public var era: String { figure.era }
    public var contribution: String { figure.contribution }
    public var relevantMicrobeSlugs: [String] { figure.relevantMicrobeSlugs }
    public var crossPortfolioBridges: [String] { figure.crossPortfolioBridges }
    public var gateID: String { figure.gateID }

    public init(
        figure: HistoricalContextFigure,
        authoring: HistoricalContextAuthoring = .placeholder
    ) {
        self.figure = figure
        self.authoring = authoring
    }
}
