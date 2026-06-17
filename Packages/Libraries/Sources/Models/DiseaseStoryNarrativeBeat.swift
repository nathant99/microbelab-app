import Foundation

/// One of the four canonical narrative beats inside a Phase 3 disease-story
/// arc. The beat sequence is the same across all 4 arcs (handwashing /
/// vaccinePriming / antibioticStewardship / outbreakRecovery) per the
/// pedagogy spine codified in `Docs/TECHNICAL_DESIGN.md` § Phase 3:
///
/// 1. **`.introduction`** — the body / community is at rest. Names the
///    primitive the arc will surface. No conflict, no fear hook.
/// 2. **`.witness`** — something changes. Sets the conditions the arc will
///    address (a microbe arrives / the kid notices something different).
///    Trauma-informed: framed as observation, NEVER as alarm.
/// 3. **`.action`** — the helper enters (soap / vaccine library / careful
///    antibiotic / neighbor care). Frames the intervention as kind +
///    competent, never as warfare.
/// 4. **`.reflection`** — the body / community settles. Names what the kid
///    can carry forward. No "victory" lexicon; the kid walks away with a
///    quieter understanding.
///
/// **Important** (per ADR-016 + `.claude/rules/trauma-informed-content.md`):
/// prose body for each beat is reviewer-blocked. This enum carries the
/// *structural metadata* per beat (`displayTitle` + `primitive`) so the
/// scene + view scaffolds can surface a status chip + beat label even
/// while the body content is `.placeholder`. The reviewer pathway flips
/// the per-beat `authoring` to `.reviewerSignedOff` when prose is ready;
/// consuming views MUST gate body rendering on that state.
public nonisolated enum DiseaseStoryNarrativeBeat: String, Codable, Sendable, CaseIterable, Identifiable {
    case introduction
    case witness
    case action
    case reflection

    public var id: String { rawValue }

    /// Canonical sort order — the kid steps through beats in this sequence.
    /// CaseIterable already gives the order via the declaration sequence,
    /// but pinning it via `index` lets the scene + tests reason about
    /// "advance to next beat" + "reset to first" invariants without
    /// repeating the case ordering.
    public var index: Int {
        switch self {
        case .introduction: return 0
        case .witness:      return 1
        case .action:       return 2
        case .reflection:   return 3
        }
    }

    /// Kid-readable beat title. Safe to surface while the body content is
    /// `.placeholder` because the title alone doesn't promise prose the
    /// reviewer hasn't signed off on yet. The title carries the beat's
    /// pedagogy spine without the per-arc prose.
    public var displayTitle: String {
        switch self {
        case .introduction: return "At rest"
        case .witness:      return "Something changes"
        case .action:       return "A helper arrives"
        case .reflection:   return "Settling"
        }
    }

    /// Per-beat curriculum primitive — used by the scene + view scaffolds
    /// to surface a structural hint while prose is `.placeholder`. The
    /// primitive is shared across arcs because the pedagogy spine is the
    /// same; only per-arc-per-beat prose differs (which is the reviewer-
    /// blocked layer).
    public var primitive: String {
        switch self {
        case .introduction: return "the steady state"
        case .witness:      return "noticing the change"
        case .action:       return "the kind intervention"
        case .reflection:   return "what the kid carries forward"
        }
    }
}

/// A scaffolded per-arc-per-beat narrative record. The structural surface
/// (arc + beat + authoring + reviewer-signoff state) ships now; the prose
/// body is reviewer-blocked per ADR-016 + `.claude/rules/trauma-informed-content.md`.
public nonisolated struct DiseaseStoryNarrativeBeatRecord: Codable, Sendable, Equatable, Identifiable {
    public let arc: DiseaseStoryArc
    public let beat: DiseaseStoryNarrativeBeat
    /// Re-use the existing `DiseaseStoryAuthoring` enum so the scaffold
    /// shares the same gate semantics the consuming `DiseaseStoryService`
    /// already pins.
    public let authoring: DiseaseStoryAuthoring

    /// Composite id so the catalog can carry all 16 entries
    /// (4 arcs × 4 beats) in a single deduplicated collection.
    public var id: String { "\(arc.rawValue).\(beat.rawValue)" }

    public init(
        arc: DiseaseStoryArc,
        beat: DiseaseStoryNarrativeBeat,
        authoring: DiseaseStoryAuthoring = .placeholder
    ) {
        self.arc = arc
        self.beat = beat
        self.authoring = authoring
    }

    /// Pedagogy-spine display title — combines the arc-level primitive with
    /// the beat-level position. The structural metadata is safe to surface
    /// while prose is reviewer-blocked because it never makes claims the
    /// reviewer hasn't signed off on; it only restates what the kid already
    /// sees in the menu chrome.
    public var beatDisplayTitle: String {
        "\(arc.displayTitle) — \(beat.displayTitle)"
    }
}

/// Canonical 16-entry catalog (4 arcs × 4 beats). Order is load-bearing:
/// arcs follow the canonical `DiseaseStoryArc` order (handwashing →
/// antibioticStewardship → vaccinePriming → outbreakRecovery — the
/// gentlest-first sequence per `DiseaseStoryService` catalog ordering);
/// beats follow the `DiseaseStoryNarrativeBeat.index` sequence. Every
/// entry ships `.placeholder` until reviewer signoff.
public nonisolated enum DiseaseStoryNarrativeCatalog {
    /// All 16 canonical records, in the canonical arc-then-beat order.
    public static let canonicalRecords: [DiseaseStoryNarrativeBeatRecord] = {
        var out: [DiseaseStoryNarrativeBeatRecord] = []
        // arcs in the canonical gentlest-first order
        let arcs: [DiseaseStoryArc] = [
            .handwashing,
            .antibioticStewardship,
            .vaccinePriming,
            .outbreakRecovery,
        ]
        let beats: [DiseaseStoryNarrativeBeat] = [
            .introduction,
            .witness,
            .action,
            .reflection,
        ]
        for arc in arcs {
            for beat in beats {
                out.append(DiseaseStoryNarrativeBeatRecord(arc: arc, beat: beat))
            }
        }
        return out
    }()

    /// Return all 4 beats for a given arc, in canonical beat order.
    public static func beats(for arc: DiseaseStoryArc) -> [DiseaseStoryNarrativeBeatRecord] {
        canonicalRecords.filter { $0.arc == arc }
    }

    /// Total entry count — pinned by tests so a future refactor doesn't
    /// silently drop a beat or arc.
    public static let totalEntries: Int = 16
}
