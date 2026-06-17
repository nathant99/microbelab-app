import Foundation
import Models

/// `@Observable` orchestrator for the Phase 3 / Phase 4 boundary-explainer
/// catalog — the parent/educator-facing scaffold that names what's about
/// to land on the kid's surface before the corresponding ProgressionService
/// gate unlocks.
///
/// **Scope** (per `Docs/FEATURE_PLAN.md` Phase 3 line 163 + ADR-016): the
/// service does NOT author or render prose. It surfaces the catalog as
/// `[PhaseBoundaryNoteRecord]` + computes per-note presentation state by
/// combining:
///
/// 1. `PhaseBoundaryAuthoring` — `.placeholder` notes render a "Coming
///    soon" affordance; `.reviewerSignedOff` notes unlock body rendering
///    when consuming views land
/// 2. `ProgressionService` gate state — the per-note `gateID` decides
///    when the kid has reached the unlock floor (5 sessions / 8 sessions
///    etc.)
/// 3. `ParentalConsentService` opt-in — for notes whose `requiresConsent`
///    is true (disease-story + historical context), the grown-up's
///    `.diseaseStoryArcs` consent gate must be open OR the surface shows
///    the consent invitation
///
/// **Mirrors** the `DiseaseStoryService` / `VaccineExplainerService` /
/// `HistoricalContextService` shape shipped PRs #141 / #154 / #164.
///
/// Closes `Docs/FEATURE_PLAN.md` Phase 3 line 163.
@MainActor
@Observable
public final class PhaseBoundaryExplainerService {

    /// Per-note presentation state computed from authoring + gate state +
    /// parental consent state. Consuming views switch on this to decide
    /// the parent-facing affordance.
    public enum BoundaryPresentation: Sendable, Equatable {
        /// Kid hasn't reached the gate's session-day floor yet. The
        /// boundary explainer stays hidden — the grown-up doesn't need
        /// to think about it yet.
        case notReached(PhaseBoundaryNoteRecord)

        /// Kid has reached the gate's session-day floor AND the boundary
        /// requires consent BUT the grown-up has not yet opted in. The
        /// parental gate surfaces the explainer + a calm "Open the
        /// disease-story arcs?" invitation.
        case awaitingConsent(PhaseBoundaryNoteRecord)

        /// Kid has reached the gate's session-day floor AND (consent
        /// granted OR not required). The grown-up sees the explainer
        /// affordance + a "What your kid will see" preview. Rendering
        /// is gated on `authoring == .reviewerSignedOff`; for
        /// `.placeholder` records the view surfaces a "Coming soon"
        /// affordance instead.
        case readyToInvite(PhaseBoundaryNoteRecord)

        /// Kid has reached the gate's session-day floor AND the grown-up
        /// has already accepted the explainer (consent granted for
        /// consent-required notes; explicit ack for non-consent notes
        /// via the local hasAcknowledged set). The explainer collapses
        /// to a quieter "You've already opted in" row.
        case alreadyAccepted(PhaseBoundaryNoteRecord)
    }

    /// The canonical boundary-explainer catalog in canonical order.
    /// Order is load-bearing: disease-story arcs first (lowest gate
    /// floor at 5 sessions); historical context cards second (same
    /// gate floor); global tour third (highest gate floor at 8 sessions).
    public private(set) var catalog: [PhaseBoundaryNoteRecord]

    /// Per-note grown-up acknowledgement set. Non-consent notes
    /// (`.globalMicrobiomeTour`) use this to mark "the grown-up has
    /// seen the explainer" so the surface collapses after first viewing.
    private var acknowledgedNotes: Set<PhaseBoundaryNote> = []

    public init(catalog: [PhaseBoundaryNoteRecord]? = nil) {
        self.catalog = catalog ?? Self.canonicalCatalog()
    }

    /// The canonical Phase 3 + Phase 4 catalog — all notes in
    /// `.placeholder` authoring state. Order: disease-story →
    /// historical context → global tour (lowest gate floor first).
    public static func canonicalCatalog() -> [PhaseBoundaryNoteRecord] {
        [
            PhaseBoundaryNoteRecord(note: .diseaseStoryArcs),
            PhaseBoundaryNoteRecord(note: .historicalContextCards),
            PhaseBoundaryNoteRecord(note: .globalMicrobiomeTour),
        ]
    }

    /// Returns the per-note presentation state. Consuming views call this
    /// once per render pass to decide which surface to draw.
    ///
    /// - Parameters:
    ///   - record: The note record from the catalog.
    ///   - gateOpen: Whether the corresponding ProgressionService gate is
    ///     unlocked. Caller computes via `progression.isUnlocked(record.gateID)`.
    ///   - parentConsented: Whether the parent has granted disease-story-
    ///     arcs consent via `ParentalConsentService.hasValidConsent(for:)`.
    ///     Only consulted when `record.requiresConsent == true`.
    public func presentation(
        for record: PhaseBoundaryNoteRecord,
        gateOpen: Bool,
        parentConsented: Bool
    ) -> BoundaryPresentation {
        guard gateOpen else {
            return .notReached(record)
        }
        if record.requiresConsent && !parentConsented {
            return .awaitingConsent(record)
        }
        if acknowledgedNotes.contains(record.note) {
            return .alreadyAccepted(record)
        }
        return .readyToInvite(record)
    }

    /// Mark a non-consent note as acknowledged by the grown-up. Idempotent.
    /// Consent-required notes use the parental consent service's
    /// `hasValidConsent(for:)` check; this acknowledgement set tracks the
    /// non-consent path only (currently `.globalMicrobiomeTour`).
    public func acknowledge(_ note: PhaseBoundaryNote) {
        acknowledgedNotes.insert(note)
    }

    /// Test + parent-controls helper: clear the acknowledgement set so the
    /// explainer surfaces fresh. Called from the parental gate's "Reset
    /// boundary explainers" affordance.
    public func resetAcknowledgements() {
        acknowledgedNotes.removeAll()
    }

    /// Whether a given note is already acknowledged (helper for views that
    /// need to surface a check-glyph next to the row).
    public func hasAcknowledged(_ note: PhaseBoundaryNote) -> Bool {
        acknowledgedNotes.contains(note)
    }

    /// Lookup helper: returns the catalog record for a note, or nil if the
    /// note isn't in the catalog (defensive; future catalog overrides may
    /// omit notes in specific environments).
    public func record(for note: PhaseBoundaryNote) -> PhaseBoundaryNoteRecord? {
        catalog.first { $0.note == note }
    }
}
