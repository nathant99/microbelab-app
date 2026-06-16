import Foundation
import Models

/// `@Observable` orchestrator for the Phase 3 disease-story arc catalog.
///
/// **Scope**: structural scaffold per `Docs/FEATURE_PLAN.md` Phase 3 +
/// `Docs/TECHNICAL_DESIGN.md` § Phase 3. The service does NOT author or
/// render prose — it surfaces the catalog as a list of `DiseaseStoryArcRecord`
/// + computes per-arc presentation state by combining:
///
/// 1. `DiseaseStoryAuthoring` — `.placeholder` arcs render a "Coming soon"
///    affordance; `.reviewerSignedOff` arcs unlock prose rendering when
///    consuming views land
/// 2. `ProgressionService` gate state — the per-arc `gateID` decides which
///    Phase-3+ ProgressionService gate (`disease-story-immune` /
///    `disease-story-microbiome`) gates the arc
/// 3. `ParentalConsentService.diseaseStoryArcs` opt-in — the whole catalog
///    is parent-gated; without consent, every arc surfaces as
///    `.gatedBehindConsent` regardless of progression
///
/// **Why so minimal**: prose authoring is reviewer-blocked per
/// `.claude/rules/trauma-informed-content.md` + ADR-016. The structural
/// service can ship now so view consumers + gating + opt-in flow are wired
/// when prose lands. Per the user-direct scope discipline + the eleven-pass
/// canonical-invariant tier in `CLAUDE.md` § Xcode-managed file safety, this
/// PR ships scaffolding only; the view layer follows in a separate round.
@MainActor
@Observable
public final class DiseaseStoryService {

    /// Per-arc presentation state computed from the catalog + gate state +
    /// parental consent state. Consuming views switch on this to decide
    /// whether to render the arc, a "Coming soon" affordance, a gate-status
    /// hint, or a parental-consent prompt.
    public enum ArcPresentation: Sendable, Equatable {
        /// Arc is reviewer-signoff complete + gate is open + parent has
        /// opted in. Safe to render the arc body. (Wire when arcs author.)
        case ready(DiseaseStoryArcRecord)

        /// Arc body is `.placeholder` or `.draftAwaitingReview`. Even if
        /// the gate is open + parent opted in, the arc shows a "Coming
        /// soon" affordance because prose is reviewer-blocked.
        case authoringPending(DiseaseStoryArcRecord)

        /// Gate is still locked (not enough sessions / scene visits / immune
        /// runs). Render gate-hint copy via
        /// `ProgressionService.unlockHint(for: arc.gateID)`.
        case gatedBehindProgression(DiseaseStoryArcRecord)

        /// Parent has not opted into disease-story arcs. Render the
        /// settings handoff (per `.claude/rules/age-assurance.md` opt-in
        /// default).
        case gatedBehindConsent(DiseaseStoryArcRecord)
    }

    /// The four canonical arcs in canonical order. Order is load-bearing:
    /// the gentlest arc (handwashing) is first so the kid's first exposure
    /// to the disease-story menu doesn't lead with antibiotic-resistance.
    public private(set) var catalog: [DiseaseStoryArcRecord]

    public init(catalog: [DiseaseStoryArcRecord]? = nil) {
        self.catalog = catalog ?? Self.canonicalCatalog()
    }

    /// The canonical Phase 3 catalog — all four arcs in `.placeholder`
    /// authoring state. Order: gentlest → community-scale.
    public static func canonicalCatalog() -> [DiseaseStoryArcRecord] {
        [
            DiseaseStoryArcRecord(arc: .handwashing),
            DiseaseStoryArcRecord(arc: .vaccinePriming),
            DiseaseStoryArcRecord(arc: .antibioticStewardship),
            DiseaseStoryArcRecord(arc: .outbreakRecovery)
        ]
    }

    /// Returns the per-arc presentation state for the given record.
    /// Consuming views call this once per render pass to decide which
    /// surface to draw.
    ///
    /// - Parameters:
    ///   - record: The arc record from the catalog.
    ///   - gateOpen: Whether the corresponding ProgressionService gate is
    ///     unlocked. Caller computes via
    ///     `progression.isUnlocked(record.gateID)`.
    ///   - parentConsented: Whether the parent has opted IN to disease-
    ///     story arcs via `ParentalConsentService.diseaseStoryArcs`.
    public func presentation(
        for record: DiseaseStoryArcRecord,
        gateOpen: Bool,
        parentConsented: Bool
    ) -> ArcPresentation {
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

    /// Lookup helper: returns the catalog record for an arc, or nil if the
    /// arc isn't in the catalog (defensive; future catalog overrides may
    /// omit arcs in specific environments).
    public func record(for arc: DiseaseStoryArc) -> DiseaseStoryArcRecord? {
        catalog.first { $0.arc == arc }
    }
}
