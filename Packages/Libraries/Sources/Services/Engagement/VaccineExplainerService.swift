import Foundation
import Models

/// `@Observable` orchestrator for the Phase 3 vaccine mini-explainer per
/// `Docs/FEATURE_PLAN.md` § Phase 3 + `Docs/TECHNICAL_DESIGN.md` § Phase 3.
///
/// **Scope**: structural scaffold that mirrors `DiseaseStoryService` for
/// the single vaccine-priming surface. The service does NOT author or
/// render prose — it surfaces the 4 canonical pedagogy beats as
/// `VaccineExplainerStepRecord` values + computes per-step presentation
/// state by combining:
///
/// 1. `VaccineExplainerAuthoringState` — `.placeholder` steps render a
///    "Coming soon" affordance; `.reviewerSignedOff` steps unlock prose
///    rendering when consuming views land.
/// 2. The `disease-story-immune` gate (5 sessions + 3 immune runs) — the
///    explainer rides the same gate as the `vaccinePriming` disease-story
///    arc so the kid reaches both at the same progression boundary.
/// 3. `ParentalConsentService.diseaseStoryArcs` opt-in — the whole
///    explainer is parent-gated; without consent the entire surface
///    surfaces as `.gatedBehindConsent`.
///
/// **Why so minimal**: prose authoring is reviewer-blocked per
/// `.claude/rules/trauma-informed-content.md` + ADR-016. The structural
/// service can ship now so view consumers + gating + opt-in flow are wired
/// when prose lands. Per the user-direct scope discipline + the eleven-pass
/// canonical-invariant tier in `CLAUDE.md` § Xcode-managed file safety, this
/// PR ships scaffolding only; the view layer follows in a separate round.
@MainActor
@Observable
public final class VaccineExplainerService {

    /// Per-step presentation state computed from the catalog + gate state +
    /// parental consent state. Consuming views switch on this to decide
    /// whether to render the step body, a "Coming soon" affordance, a
    /// gate-status hint, or a parental-consent prompt.
    public enum StepPresentation: Sendable, Equatable {
        /// Step is reviewer-signoff complete + gate is open + parent has
        /// opted in. Safe to render the step body. (Wire when steps author.)
        case ready(VaccineExplainerStepRecord)

        /// Step body is `.placeholder` or `.draftAwaitingReview`. Even if
        /// the gate is open + parent opted in, the step shows a "Coming
        /// soon" affordance because prose is reviewer-blocked.
        case authoringPending(VaccineExplainerStepRecord)

        /// `disease-story-immune` gate is still locked. Render gate-hint
        /// copy via `ProgressionService.unlockHint(for: explainerGateID)`.
        case gatedBehindProgression(VaccineExplainerStepRecord)

        /// Parent has not opted into disease-story arcs (the explainer
        /// shares the same consent kind). Render the settings handoff per
        /// `.claude/rules/age-assurance.md` opt-in default.
        case gatedBehindConsent(VaccineExplainerStepRecord)
    }

    /// The canonical gate ID — shared with the `vaccinePriming`
    /// disease-story arc so the kid reaches both surfaces at the same
    /// progression boundary (5 sessions + 3 immune runs).
    public static let explainerGateID = "disease-story-immune"

    /// The four canonical pedagogy beats in canonical order. Order is
    /// load-bearing: the gentlest beat (introduction) is first so the kid's
    /// first exposure to the explainer doesn't lead with booster rationale.
    public private(set) var catalog: [VaccineExplainerStepRecord]

    public init(catalog: [VaccineExplainerStepRecord]? = nil) {
        self.catalog = catalog ?? Self.canonicalCatalog()
    }

    /// The canonical Phase 3 catalog — all four steps in `.placeholder`
    /// authoring state. Order: gentlest → booster-rationale.
    public static func canonicalCatalog() -> [VaccineExplainerStepRecord] {
        [
            VaccineExplainerStepRecord(step: .introduction),
            VaccineExplainerStepRecord(step: .antibodyPriming),
            VaccineExplainerStepRecord(step: .memoryFormation),
            VaccineExplainerStepRecord(step: .boosterRationale),
        ]
    }

    /// Returns the per-step presentation state for the given record.
    /// Consuming views call this once per render pass to decide which
    /// surface to draw.
    ///
    /// - Parameters:
    ///   - record: The step record from the catalog.
    ///   - gateOpen: Whether the `disease-story-immune` gate is unlocked.
    ///     Caller computes via
    ///     `progression.isUnlocked(VaccineExplainerService.explainerGateID)`.
    ///   - parentConsented: Whether the parent has opted IN to
    ///     disease-story arcs via
    ///     `ParentalConsentService.diseaseStoryArcs`. The explainer shares
    ///     the same consent kind.
    public func presentation(
        for record: VaccineExplainerStepRecord,
        gateOpen: Bool,
        parentConsented: Bool
    ) -> StepPresentation {
        guard parentConsented else {
            return .gatedBehindConsent(record)
        }
        guard gateOpen else {
            return .gatedBehindProgression(record)
        }
        switch record.authoring {
        case .placeholder, .draftAwaitingReview:
            return .authoringPending(record)
        case .reviewerSignedOff:
            return .ready(record)
        }
    }

    /// Lookup helper: returns the catalog record for a step, or nil if the
    /// step isn't in the catalog (defensive; future catalog overrides may
    /// omit steps in specific environments).
    public func record(for step: VaccineExplainerStep) -> VaccineExplainerStepRecord? {
        catalog.first { $0.step == step }
    }
}
