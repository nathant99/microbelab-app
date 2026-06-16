import Foundation

/// One of the four canonical Phase 3 disease-story arcs scoped in
/// `Docs/TECHNICAL_DESIGN.md` § Phase 3 + `Docs/FEATURE_PLAN.md` § Phase 3.
///
/// **Important**: prose content for these arcs is NOT authored in-app. Every
/// arc ships with `authoring == .placeholder` until the SAMHSA TIP 57
/// register-trained external reviewer signs off per
/// `.claude/rules/trauma-informed-content.md` + ADR-016 (DN-S trauma-gated
/// story-axis ADR-approval pathway). The catalog ships the metadata + gate
/// keys so the structural scaffold can be wired (`ProgressionService` gates,
/// `ParentalConsentService.diseaseStoryArcs` opt-in, navigation menu state)
/// without committing to prose that has not been reviewed.
public nonisolated enum DiseaseStoryArc: String, Codable, Sendable, CaseIterable, Identifiable {
    /// Handwashing micro-arc — the simplest hygiene story. Frames soap as a
    /// kind helper that loosens the microbe layer so plain water can rinse it
    /// away. Trauma-informed register: no "germs are everywhere" fear hook;
    /// no shame on the kid for not washing already.
    case handwashing

    /// Antibiotic stewardship — when antibiotics help, when they hurt, why
    /// finishing the course matters. Frames antibiotics as strong helpers
    /// that need careful timing, not as weapons or judgments.
    case antibioticStewardship

    /// Vaccine priming — the body's library of shapes grows from a tiny
    /// taste. Pairs structurally with the Phase 2 adaptive-immunity arc
    /// (B-cell antibody matching) so the kid sees the connection without
    /// re-teaching the primitive.
    case vaccinePriming

    /// Outbreak recovery — community-scale care after a hard time. Frames
    /// recovery as collective + gentle, NOT as victory. COVID-trauma-
    /// sensitive per the app's overarching framing in `CLAUDE.md` § overview.
    case outbreakRecovery

    public var id: String { rawValue }

    /// Kid-readable title; safe to surface in menus while the body content
    /// is `.placeholder` because the title alone doesn't promise anything
    /// the kid can't already infer from the menu chrome.
    public var displayTitle: String {
        switch self {
        case .handwashing:          return "How soap helps"
        case .antibioticStewardship: return "Strong helpers, careful timing"
        case .vaccinePriming:        return "A library of shapes"
        case .outbreakRecovery:      return "Healing together"
        }
    }

    /// Stable curriculum hook. NGSS / CDC-aligned framing; used by the
    /// gating service to decide which arc the kid is being scaffolded
    /// toward when the disease-story-immune gate flips open.
    public var primitive: String {
        switch self {
        case .handwashing:          return "physical removal of microbes (hygiene)"
        case .antibioticStewardship: return "antibiotic dosing curve + resistance evolution"
        case .vaccinePriming:        return "antibody memory + immune priming"
        case .outbreakRecovery:      return "community-scale convalescent care"
        }
    }

    /// Which gate this arc lives behind. `vaccinePriming` rides the immune
    /// gate (it builds on the B-cell arc); the other three ride the
    /// microbiome gate (they build on the ecology surfaces).
    public var gateID: String {
        switch self {
        case .vaccinePriming:       return "disease-story-immune"
        case .handwashing,
             .antibioticStewardship,
             .outbreakRecovery:     return "disease-story-microbiome"
        }
    }
}

/// Per-arc authoring state. The `.placeholder` state is load-bearing: the
/// catalog can ship all four arcs structurally while keeping prose content
/// reviewer-blocked. Consuming views MUST gate rendering on
/// `authoring == .reviewerSignedOff` so the kid never sees draft prose.
public nonisolated enum DiseaseStoryAuthoring: String, Codable, Sendable, CaseIterable {
    /// Structural placeholder — title + primitive + gate metadata only. No
    /// prose. The menu surfaces a "Coming soon" affordance instead of the
    /// arc body. This is the default for every arc in Phase 3 + Phase 3.1
    /// rounds until reviewer-signoff lands.
    case placeholder

    /// Draft prose authored but NOT yet reviewer-signed-off. Visible to
    /// the implementing session for review; views still surface the
    /// "Coming soon" affordance until `.reviewerSignedOff`.
    case draftAwaitingReview

    /// Reviewer-signed-off prose, kid-safe to render. Per ADR-016 the
    /// labsmith reviewer pathway counts as signoff for the trauma-gated
    /// DN-S story-axis; per-MicrobeLab arcs follow the same pathway.
    case reviewerSignedOff
}

/// A scaffolded disease-story arc record. Carries metadata + gate keys +
/// authoring state. Prose body lives in the consuming view layer (when
/// authored) — this record stays minimal so the catalog can grow without
/// inflating value-type surfaces.
public nonisolated struct DiseaseStoryArcRecord: Codable, Sendable, Equatable, Identifiable {
    public let arc: DiseaseStoryArc
    public let authoring: DiseaseStoryAuthoring

    public var id: String { arc.rawValue }
    public var displayTitle: String { arc.displayTitle }
    public var primitive: String { arc.primitive }
    public var gateID: String { arc.gateID }

    public init(arc: DiseaseStoryArc, authoring: DiseaseStoryAuthoring = .placeholder) {
        self.arc = arc
        self.authoring = authoring
    }
}
