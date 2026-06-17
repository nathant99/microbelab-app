import Foundation

/// One of the four canonical pedagogy beats of the Phase 3 vaccine
/// mini-explainer — the antibody-priming visualization scoped in
/// `Docs/FEATURE_PLAN.md` § Phase 3 + `Docs/TECHNICAL_DESIGN.md` § Phase 3.
///
/// The mini-explainer pairs structurally with the Phase 2 adaptive-immunity
/// arc (B-cell antibody matching) so the kid sees the connection without
/// re-teaching the primitive — vaccines are the body's library learning a
/// shape AHEAD of meeting it live.
///
/// **Important**: prose content for these steps is NOT authored in-app. Every
/// step ships with `authoring == .placeholder` until the SAMHSA TIP 57
/// register-trained external reviewer signs off per
/// `.claude/rules/trauma-informed-content.md` + ADR-016 (DN-S trauma-gated
/// story-axis ADR-approval pathway). The catalog ships the metadata so the
/// structural scaffold can be wired (`ProgressionService.isUnlocked(_:)`
/// on the `disease-story-immune` gate, `ParentalConsentService.diseaseStoryArcs`
/// opt-in) without committing to prose that has not been reviewed.
public nonisolated enum VaccineExplainerStep: String, Codable, Sendable, CaseIterable, Identifiable {
    /// Step 1 — gentle introduction. Vaccines as a kind helper, not a fear
    /// hook. Frames the surface for the rest of the explainer.
    case introduction

    /// Step 2 — antibody priming. The B-cell library practices matching a
    /// new shape before the body meets the live antigen.
    case antibodyPriming

    /// Step 3 — memory formation. The body keeps a note of the matched
    /// shape so it recognizes it faster next time. Inherits the Phase 2
    /// adaptive-immunity register (memory cells, library of shapes).
    case memoryFormation

    /// Step 4 — booster rationale. Why a second dose helps the library
    /// remember more steadily. Frames boosters as care + patience, never
    /// as failure of the first dose.
    case boosterRationale

    public var id: String { rawValue }

    /// Kid-readable title; safe to surface in the explainer's step picker
    /// while the body content is `.placeholder` because the title alone
    /// doesn't promise anything the kid can't already infer.
    public var displayTitle: String {
        switch self {
        case .introduction:    return "A gentle introduction"
        case .antibodyPriming: return "Practicing the shape"
        case .memoryFormation: return "The library remembers"
        case .boosterRationale: return "Why a second dose helps"
        }
    }

    /// Stable curriculum hook. Used by the consuming view + ProgressReport
    /// service to mark which immune-system primitive the step embodies.
    public var primitive: String {
        switch self {
        case .introduction:     return "vaccine framing — care helper, never fear hook"
        case .antibodyPriming:  return "B-cell antibody library learning a new shape"
        case .memoryFormation:  return "memory cells + faster re-recognition"
        case .boosterRationale: return "dose timing + library reinforcement"
        }
    }
}

/// Authoring state for a vaccine explainer step. Mirrors
/// `DiseaseStoryAuthoring` per ADR-016 so the same reviewer-signoff
/// pathway covers both surfaces.
public nonisolated enum VaccineExplainerAuthoringState: String, Codable, Sendable, CaseIterable {
    /// Structural placeholder — title + primitive only. No prose. The view
    /// surfaces a "Coming soon" affordance instead of the step body.
    case placeholder

    /// Draft prose authored but NOT yet reviewer-signed-off. Visible to the
    /// implementing session for review; views still surface the
    /// "Coming soon" affordance until `.reviewerSignedOff`.
    case draftAwaitingReview

    /// Reviewer-signed-off prose, kid-safe to render. Per ADR-016 the
    /// labsmith reviewer pathway counts as signoff for the trauma-gated
    /// DN-S story-axis; per-MicrobeLab arcs + the vaccine explainer follow
    /// the same pathway.
    case reviewerSignedOff
}

/// A scaffolded vaccine explainer step record. Carries the step + authoring
/// state. Prose body lives in the consuming view layer (when authored) —
/// this record stays minimal so the catalog can grow without inflating
/// value-type surfaces.
public nonisolated struct VaccineExplainerStepRecord: Codable, Sendable, Equatable, Identifiable {
    public let step: VaccineExplainerStep
    public let authoring: VaccineExplainerAuthoringState

    public var id: String { step.rawValue }
    public var displayTitle: String { step.displayTitle }
    public var primitive: String { step.primitive }

    public init(step: VaccineExplainerStep,
                authoring: VaccineExplainerAuthoringState = .placeholder) {
        self.step = step
        self.authoring = authoring
    }
}
