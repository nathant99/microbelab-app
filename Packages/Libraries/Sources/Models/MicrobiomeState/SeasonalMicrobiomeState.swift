import Foundation

/// Per-season simulation lever for the Phase 4 seasonal-microbiome scene
/// scaffold. Pairs with `Services/Engagement/SeasonalEventService` (PR #143)
/// + the `ExperimentsService.seasonal_content_gate` pilot (PR #136). The
/// scene + view consumers land in a focused future round; this value-type
/// scaffold lets the pure-value engine + simulator wiring be unit-tested
/// without a GPU context, mirroring the Oral / Skin / Soil ecology scaffolds
/// from PRs #124 / #130 / #131.
///
/// Mapping to `FeedingMode` for the underlying `MicrobiomeSimulator`:
///
/// | SeasonalLoad      | FeedingMode  | Why                                  |
/// |-------------------|--------------|--------------------------------------|
/// | `.winterCold`     | `.balanced`  | The body's library is busy on a respiratory bug; community is holding its normal mix |
/// | `.springAllergy`  | `.sugar`     | Pollen disturbance + IgE response tilts the ecology — modeled as a sugar-style growth spike, not as "fighting" |
/// | `.summerWarm`     | `.fiber`     | Summer produce season — fiber-loving microbes thrive |
/// | `.autumnSettle`   | `.none`      | The body is recovering from summer + transitioning; community settles |
///
/// **Trauma-informed register (load-bearing)**: cold is "the immune library
/// is busy" NOT "the body is sick"; allergy is "the body is noticing pollen"
/// NOT "attacked"; pollen is sensory NOT enemy. The per-load mentor copy +
/// the display labels stay reviewer-safe at the per-load caption tier (this
/// is body-affirming framing rather than disease prose, so it does NOT cross
/// the ADR-016 disease-story-arc reviewer line — confirmed via the stoplist
/// test in `SeasonalMicrobiomeStateTests`). The scene + scene-level mentor
/// cue copy + view-level explainer prose still gate on reviewer signoff per
/// ADR-016 + ADR-011 Rule 4.
public nonisolated enum SeasonalLoad: String, Codable, Sendable, CaseIterable {
    case winterCold
    case springAllergy
    case summerWarm
    case autumnSettle

    /// Underlying `FeedingMode` the shared `MicrobiomeSimulator` consumes.
    public var feedingMode: FeedingMode {
        switch self {
        case .winterCold: return .balanced
        case .springAllergy: return .sugar
        case .summerWarm: return .fiber
        case .autumnSettle: return .none
        }
    }

    /// Trauma-informed display label. Kid-readable + warm.
    public var displayName: String {
        switch self {
        case .winterCold: return "Winter cold"
        case .springAllergy: return "Spring pollen"
        case .summerWarm: return "Summer warm"
        case .autumnSettle: return "Autumn settling"
        }
    }

    /// SF Symbol for the segmented picker.
    public var systemImage: String {
        switch self {
        case .winterCold: return "snowflake"
        case .springAllergy: return "leaf"
        case .summerWarm: return "sun.max.fill"
        case .autumnSettle: return "wind"
        }
    }
}

/// Snapshot of the seasonal-microbiome simulator at a given tick. Pure value
/// type — wraps a standard `MicrobiomeState` so the underlying engine can
/// run the same population math, and adds a seasonal-specific surface for
/// the four-case season lever.
///
/// The `slot` for seasonal scenarios is `.largeIntestine` because the gut
/// is the primary microbiome surface most responsive to season-driven
/// dietary + immune-system shifts. This mirrors the canonical FEATURE_PLAN
/// description of seasonal-microbiome simulation as a gut-ecology surface
/// reflecting cold / allergy / produce-season / recovery cycles.
public nonisolated struct SeasonalMicrobiomeState: Codable, Sendable, Equatable {
    public let underlying: MicrobiomeState
    public let load: SeasonalLoad

    public init(underlying: MicrobiomeState, load: SeasonalLoad) {
        self.underlying = underlying
        self.load = load
    }

    public var tickCount: Int { underlying.tickCount }
    public var totalPopulation: Int { underlying.totalPopulation }

    /// Empty starting state in the `.largeIntestine` slot under `.winterCold`.
    /// Winter is the default starting season because most kid-onboarding
    /// happens during the school year — sets up the first-launch experience
    /// against a familiar context, never an unfamiliar one.
    public static var empty: SeasonalMicrobiomeState {
        SeasonalMicrobiomeState(
            underlying: .empty(in: .largeIntestine),
            load: .winterCold
        )
    }

    /// Per-tick advance of the seasonal-stable tick run.
    ///
    /// - **`.winterCold`** → `prior + 1`. The body holds its winter mix — the
    ///   immune library is doing its work without disturbing the gut
    ///   community. The stable run extends.
    /// - **`.springAllergy`** → `0`. The IgE response surfaces — gut
    ///   community shifts. Resetting is NOT shame; allergy is sensory not
    ///   moral.
    /// - **`.summerWarm`** → `prior + 1`. Fiber-loving microbes thrive on
    ///   summer produce; the stable run extends.
    /// - **`.autumnSettle`** → `prior`. The body is recovering from summer
    ///   + transitioning; community settles. Holding the run in place
    ///   mirrors "settling" rather than "progressing" or "regressing".
    ///
    /// Load-bearing for the `seasonalAwareness` achievement criterion (PR
    /// for Phase 4 advanced achievements). Pure-value derivation so the
    /// threshold logic is unit-testable without a GPU context.
    public static func nextStableRun(prior: Int, load: SeasonalLoad) -> Int {
        switch load {
        case .winterCold, .summerWarm: return prior + 1
        case .springAllergy: return 0
        case .autumnSettle: return prior
        }
    }
}
