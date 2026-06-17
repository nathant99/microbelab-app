import Foundation
import Models

/// `@Observable` orchestrator for the Phase 3 historical context card
/// catalog.
///
/// **Scope**: structural scaffold per `Docs/FEATURE_PLAN.md` § Phase 3.
/// The service does NOT author or render prose — it surfaces the catalog
/// as a list of `HistoricalContextCardRecord` + computes per-card
/// presentation state by combining:
///
/// 1. `HistoricalContextAuthoring` — `.placeholder` cards render a "Coming
///    soon" affordance; `.reviewerSignedOff` cards unlock prose rendering
///    when consuming views land
/// 2. `ProgressionService.disease-story-immune` gate state (PR #137) —
///    requires 5 sessions + 3 immune runs before the gate opens
/// 3. `ParentalConsentService.diseaseStoryArcs` opt-in — historical context
///    cards share the same parent-consent surface as the disease-story arcs
///    they curricularly accompany; without consent every card surfaces as
///    `.gatedBehindConsent` regardless of progression
///
/// **Why so minimal**: prose authoring is reviewer-blocked per
/// `.claude/rules/trauma-informed-content.md` § historical figure framing +
/// CQ CONTENT_STYLE_GUIDE.md § 4.5 anti-credentialism gate + ADR-016. The
/// structural service can ship now so view consumers + gating + opt-in flow
/// are wired when prose lands. Pattern mirrors `DiseaseStoryService`
/// (PR #141) + `GlobalMicrobiomeTourService` (Option 5).
@MainActor
@Observable
public final class HistoricalContextService {

    /// Per-card presentation state computed from the catalog + gate state +
    /// parental consent state. Consuming views switch on this to decide
    /// whether to render the card, a "Coming soon" affordance, a gate-status
    /// hint, or a parental-consent prompt.
    public enum CardPresentation: Sendable, Equatable {
        /// Card is reviewer-signoff complete + gate is open + parent has
        /// opted in. Safe to render the card body. (Wire when cards author.)
        case ready(HistoricalContextCardRecord)

        /// Card body is `.placeholder` or `.draftAwaitingReview`. Even if
        /// the gate is open + parent opted in, the card shows a "Coming
        /// soon" affordance because prose is reviewer-blocked.
        case authoringPending(HistoricalContextCardRecord)

        /// Gate is still locked (not enough sessions / immune runs). Render
        /// gate-hint copy via
        /// `ProgressionService.unlockHint(for: "disease-story-immune")`.
        case gatedBehindProgression(HistoricalContextCardRecord)

        /// Parent has not opted into disease-story arcs. Render the
        /// settings handoff (per `.claude/rules/age-assurance.md` opt-in
        /// default).
        case gatedBehindConsent(HistoricalContextCardRecord)
    }

    /// The four canonical cards in canonical order. Order is load-bearing:
    /// the methodology spine (Koch's postulates) leads so kids meet the
    /// pattern-noticing register first; Pasteur + Salk follow (vaccine
    /// arcs); Marshall closes (kid-scientist register — patient observation
    /// paying off). Order: Koch → Pasteur → Salk → Marshall.
    public private(set) var catalog: [HistoricalContextCardRecord]

    public init(catalog: [HistoricalContextCardRecord]? = nil) {
        self.catalog = catalog ?? Self.canonicalCatalog()
    }

    /// The canonical Phase 3 catalog — all four cards in `.placeholder`
    /// authoring state. Order: methodology spine → vaccine arcs → kid-
    /// scientist register.
    public static func canonicalCatalog() -> [HistoricalContextCardRecord] {
        [
            HistoricalContextCardRecord(figure: .koch),
            HistoricalContextCardRecord(figure: .pasteur),
            HistoricalContextCardRecord(figure: .salk),
            HistoricalContextCardRecord(figure: .marshall)
        ]
    }

    /// Returns the per-card presentation state for the given record.
    /// Consuming views call this once per render pass to decide which
    /// surface to draw.
    ///
    /// - Parameters:
    ///   - record: The card record from the catalog.
    ///   - gateOpen: Whether the `disease-story-immune` gate is unlocked.
    ///     Caller computes via
    ///     `progression.isUnlocked("disease-story-immune")`.
    ///   - parentConsented: Whether the parent has opted IN to disease-
    ///     story arcs via `ParentalConsentService.diseaseStoryArcs`. Per
    ///     ADR-016 historical context cards share the same consent surface
    ///     as the disease-story arcs they accompany.
    public func presentation(
        for record: HistoricalContextCardRecord,
        gateOpen: Bool,
        parentConsented: Bool
    ) -> CardPresentation {
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

    /// Lookup helper: returns the catalog record for a figure, or nil if
    /// the figure isn't in the catalog (defensive; future catalog overrides
    /// may omit figures in specific environments).
    public func record(for figure: HistoricalContextFigure) -> HistoricalContextCardRecord? {
        catalog.first { $0.figure == figure }
    }
}
