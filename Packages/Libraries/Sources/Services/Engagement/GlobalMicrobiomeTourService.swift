import Foundation
import Models

/// `@Observable` orchestrator for the Phase 4 global-microbiome-tour stop
/// catalog.
///
/// **Scope**: structural scaffold per `Docs/FEATURE_PLAN.md` Phase 4 +
/// `Docs/TECHNICAL_DESIGN.md` § Phase 4. The service does NOT author or
/// render prose — it surfaces the catalog as a list of
/// `GlobalMicrobiomeTourStopRecord` + computes per-stop presentation state
/// by combining:
///
/// 1. `GlobalMicrobiomeTourAuthoring` — `.placeholder` stops render a
///    "Coming soon" affordance; `.reviewerSignedOff` stops unlock prose
///    rendering when consuming views land
/// 2. `ProgressionService.global-microbiome-tour` gate state (PR #137) —
///    requires 8 sessions + 4 distinct ecologies visited before the gate
///    opens
///
/// **Why so minimal**: prose authoring is reviewer-blocked per
/// `.claude/rules/distributed-narrative.md` § cultural-sensitivity gates
/// (Yellowstone Indigenous TEK credit is load-bearing; deep-sea framing
/// for wonder over fear) + ADR-016. The structural service can ship now so
/// view consumers + gating are wired when prose lands. Pattern mirrors
/// `DiseaseStoryService` (PR #141) + `VaccineExplainerService` (PR #154).
///
/// **Distinct from disease-story consent gate**: this surface is NOT
/// gated behind `ParentalConsentService.diseaseStoryArcs` because the tour
/// is ecology + adaptation framing rather than disease prose. The
/// `global-microbiome-tour` gate from `ProgressionService` is the only
/// gate; once it opens and stops gain reviewer-signed-off prose, the kid
/// sees the surface.
@MainActor
@Observable
public final class GlobalMicrobiomeTourService {

    /// Per-stop presentation state computed from the catalog + gate state.
    /// Consuming views switch on this to decide whether to render the stop,
    /// a "Coming soon" affordance, or a gate-status hint.
    public enum StopPresentation: Sendable, Equatable {
        /// Stop is reviewer-signoff complete + gate is open. Safe to render
        /// the stop body. (Wire when stops author.)
        case ready(GlobalMicrobiomeTourStopRecord)

        /// Stop body is `.placeholder` or `.draftAwaitingReview`. Even if
        /// the gate is open, the stop shows a "Coming soon" affordance
        /// because prose is reviewer-blocked.
        case authoringPending(GlobalMicrobiomeTourStopRecord)

        /// Gate is still locked (not enough sessions / ecologies visited).
        /// Render gate-hint copy via
        /// `ProgressionService.unlockHint(for: stop.gateID)`.
        case gatedBehindProgression(GlobalMicrobiomeTourStopRecord)
    }

    /// The four canonical stops in canonical order. Order is load-bearing:
    /// the kid's most-familiar habitat (human gut) sits in the middle so the
    /// tour opens with the relatively wonder-forward Yellowstone hot spring
    /// AND lands the kid in familiar territory before pivoting to the deep
    /// sea + soil. Order: hot-spring → vent → gut → underground.
    public private(set) var catalog: [GlobalMicrobiomeTourStopRecord]

    public init(catalog: [GlobalMicrobiomeTourStopRecord]? = nil) {
        self.catalog = catalog ?? Self.canonicalCatalog()
    }

    /// The canonical Phase 4 catalog — all four stops in `.placeholder`
    /// authoring state. Order: wonder-forward → familiar → expansion.
    public static func canonicalCatalog() -> [GlobalMicrobiomeTourStopRecord] {
        [
            GlobalMicrobiomeTourStopRecord(stop: .yellowstoneHotSpring),
            GlobalMicrobiomeTourStopRecord(stop: .deepSeaVent),
            GlobalMicrobiomeTourStopRecord(stop: .humanGut),
            GlobalMicrobiomeTourStopRecord(stop: .soilUnderground)
        ]
    }

    /// Returns the per-stop presentation state for the given record.
    /// Consuming views call this once per render pass to decide which
    /// surface to draw.
    ///
    /// - Parameters:
    ///   - record: The stop record from the catalog.
    ///   - gateOpen: Whether the corresponding ProgressionService gate is
    ///     unlocked. Caller computes via
    ///     `progression.isUnlocked("global-microbiome-tour")`.
    public func presentation(
        for record: GlobalMicrobiomeTourStopRecord,
        gateOpen: Bool
    ) -> StopPresentation {
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

    /// Lookup helper: returns the catalog record for a stop, or nil if the
    /// stop isn't in the catalog (defensive; future catalog overrides may
    /// omit stops in specific environments).
    public func record(for stop: GlobalMicrobiomeTourStop) -> GlobalMicrobiomeTourStopRecord? {
        catalog.first { $0.stop == stop }
    }
}
