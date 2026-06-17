import Foundation

/// One of the canonical Phase 3 / Phase 4 boundary notes — a parent/educator-
/// facing scaffold that names what's about to land on the kid's surface before
/// the corresponding ProgressionService gate unlocks.
///
/// **Scope** (per `Docs/FEATURE_PLAN.md` line 163 "Add parent/educator
/// explainer at the disease-story phase boundary (opt-in)" + ADR-016
/// trauma-gated story-axis approval pathway): the explainer carries the
/// "what's coming + how it's framed" copy that grown-ups read BEFORE consenting
/// the kid into the disease-story arcs. Pure metadata + gate keys — prose body
/// stays reviewer-blocked per `.claude/rules/trauma-informed-content.md`
/// until SAMHSA TIP 57 register signoff lands.
///
/// **Mirrors** the `DiseaseStoryArc` / `VaccineExplainerStep` /
/// `HistoricalContextCard` scaffold pattern shipped PRs #141 / #154 / #164.
public nonisolated enum PhaseBoundaryNote: String, Codable, Sendable, CaseIterable, Identifiable {
    /// Phase 3 disease-story arc boundary. Frames the four arcs (handwashing
    /// / vaccine priming / antibiotic stewardship / outbreak recovery) for
    /// the grown-up so they can decide whether to opt in.
    case diseaseStoryArcs

    /// Phase 3 historical context cards boundary. Frames the four figures
    /// (Koch / Pasteur / Salk / Marshall) — pairs with the `ParentalConsent
    /// Service.diseaseStoryArcs` consent surface per ADR-016.
    case historicalContextCards

    /// Phase 4 global-microbiome tour boundary. Distinct from disease-story
    /// arcs in NOT requiring parental consent — ecology + adaptation framing.
    /// The note is still useful to grown-ups who want to know what's
    /// coming before the kid hits the eight-session unlock.
    case globalMicrobiomeTour

    public var id: String { rawValue }

    /// Kid- AND grown-up-readable title. Safe to surface in the parental
    /// gate menu while body content is `.placeholder` because the title
    /// alone doesn't promise anything beyond what the menu chrome shows.
    public var displayTitle: String {
        switch self {
        case .diseaseStoryArcs:        return "Disease stories — what's coming"
        case .historicalContextCards:  return "Microbiology stories from history"
        case .globalMicrobiomeTour:    return "A tour of microbiomes around the world"
        }
    }

    /// Which ProgressionService gate this boundary explainer pairs with.
    /// The explainer surfaces calmly once the gate is `.readyToInvite`
    /// (kid has met the session-day floor); the grown-up's opt-in lands
    /// before the kid sees the surface.
    public var gateID: String {
        switch self {
        case .diseaseStoryArcs:        return "disease-story-microbiome"
        case .historicalContextCards:  return "disease-story-immune"
        case .globalMicrobiomeTour:    return "global-microbiome-tour"
        }
    }

    /// Whether the consuming surface requires parental consent before the
    /// kid sees the unlock. Disease-story arcs + historical context cards
    /// DO (ADR-016 trauma-gated). Global-microbiome tour does NOT (ecology
    /// + adaptation framing, no SAMHSA register weight).
    public var requiresConsent: Bool {
        switch self {
        case .diseaseStoryArcs, .historicalContextCards:
            return true
        case .globalMicrobiomeTour:
            return false
        }
    }
}

/// Per-boundary authoring state. Mirrors `DiseaseStoryAuthoring` shape so the
/// parent surface uses identical render gating. `.placeholder` is the only
/// state shipped this round — explainer prose follows when SAMHSA TIP 57
/// register-trained external reviewer signoff lands.
public nonisolated enum PhaseBoundaryAuthoring: String, Codable, Sendable, CaseIterable {
    /// Title + gate metadata only. The parent surface renders a calm
    /// "Coming soon — your kid will see this once we've reviewed it
    /// together" affordance instead of the explainer body.
    case placeholder

    /// Draft prose authored but NOT yet reviewer-signed-off.
    case draftAwaitingReview

    /// Reviewer-signed-off prose, grown-up-safe to render. Per ADR-016
    /// the labsmith reviewer pathway counts as signoff.
    case reviewerSignedOff
}

/// A boundary-explainer catalog row. Carries metadata + gate key + authoring
/// state. Prose body lives in the consuming view layer (when authored) —
/// this record stays minimal so the catalog can grow without inflating
/// value-type surfaces.
public nonisolated struct PhaseBoundaryNoteRecord: Codable, Sendable, Equatable, Identifiable {
    public let note: PhaseBoundaryNote
    public let authoring: PhaseBoundaryAuthoring

    public var id: String { note.rawValue }
    public var displayTitle: String { note.displayTitle }
    public var gateID: String { note.gateID }
    public var requiresConsent: Bool { note.requiresConsent }

    public init(note: PhaseBoundaryNote, authoring: PhaseBoundaryAuthoring = .placeholder) {
        self.note = note
        self.authoring = authoring
    }
}
