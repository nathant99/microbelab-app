import Foundation

/// Sugar-load equivalent of `FeedingMode` for the oral-cavity ecology. The
/// oral microbiome doesn't have a fiber/sugar/balanced surface the way the
/// gut does — its dominant lever is how often sugar is around + whether the
/// kid brushes (which thins plaque so no single microbe takes over).
///
/// Mapping to `FeedingMode` for the underlying `MicrobiomeSimulator`:
///
/// | OralSugarLoad   | FeedingMode |
/// |-----------------|-------------|
/// | `.water`        | `.balanced` |
/// | `.fruit`        | `.balanced` |
/// | `.sugarSnack`   | `.sugar`    |
/// | `.brush`        | `.none`     |
///
/// `.brush` maps to `.none` because brushing temporarily thins the plaque
/// layer — no microbe gets its preferred fuel. This mirrors the underlying
/// engine semantics without inventing new growth-rate math.
///
/// **Trauma-informed register**: brushing is care, not a moral test. The
/// `.brush` state surfaces "the community settles" copy, never "you should
/// have brushed" framing. See `Docs/FEATURE_PLAN.md` § Phase 2 +
/// `Packages/Libraries/Sources/Services/Resources/kit_06_oral_microbiome.json`.
public nonisolated enum OralSugarLoad: String, Codable, Sendable, CaseIterable {
    case water
    case fruit
    case sugarSnack
    case brush

    /// Underlying `FeedingMode` the shared `MicrobiomeSimulator` consumes.
    public var feedingMode: FeedingMode {
        switch self {
        case .water, .fruit: return .balanced
        case .sugarSnack: return .sugar
        case .brush: return .none
        }
    }

    /// Trauma-informed display label. Kid-readable + warm.
    public var displayName: String {
        switch self {
        case .water: return "Water"
        case .fruit: return "Fruit"
        case .sugarSnack: return "Sugar snack"
        case .brush: return "Brush"
        }
    }

    /// SF Symbol for the segmented picker.
    public var systemImage: String {
        switch self {
        case .water: return "drop.fill"
        case .fruit: return "leaf.fill"
        case .sugarSnack: return "birthday.cake.fill"
        case .brush: return "sparkles"
        }
    }
}

/// Snapshot of the oral-cavity microbiome simulator at a given tick. Pure
/// value type — wraps a standard `MicrobiomeState` so the underlying engine
/// can run the same population math, and adds an oral-specific surface for
/// the sugar-load lever.
public nonisolated struct OralMicrobiomeState: Codable, Sendable, Equatable {
    public let underlying: MicrobiomeState
    public let sugarLoad: OralSugarLoad

    public init(underlying: MicrobiomeState, sugarLoad: OralSugarLoad) {
        self.underlying = underlying
        self.sugarLoad = sugarLoad
    }

    public var tickCount: Int { underlying.tickCount }
    public var totalPopulation: Int { underlying.totalPopulation }

    /// Empty starting state in the `.oralCavity` slot.
    public static var empty: OralMicrobiomeState {
        OralMicrobiomeState(
            underlying: .empty(in: .oralCavity),
            sugarLoad: .water
        )
    }

    /// Per-tick advance of the oral-stable tick run.
    ///
    /// - **`.water` / `.fruit`** (gentle loads) → `prior + 1`. The oral
    ///   community is holding balance; the stable run extends.
    /// - **`.sugarSnack`** → `0`. Acid-makers tilt the ecology; the run
    ///   resets. (Resetting is NOT shame — it's ecology, mirroring the
    ///   per-load mentor copy in `OralMicrobiomeView.refreshMentorCue`.)
    /// - **`.brush`** → `prior`. Brushing is care, not progress. Holding
    ///   the run in place mirrors the kid's lived experience: brushing
    ///   doesn't undo a sugar snack, but it also doesn't earn more credit
    ///   than the kid already accumulated from earlier gentle loads.
    ///
    /// Load-bearing for the `oralBalanceKeeper` achievement criterion in
    /// `OralMicrobiomeView`. Pure-value derivation so the threshold logic
    /// is unit-testable without a GPU context.
    public static func nextStableRun(prior: Int, sugarLoad: OralSugarLoad) -> Int {
        switch sugarLoad {
        case .water, .fruit: return prior + 1
        case .sugarSnack: return 0
        case .brush: return prior
        }
    }
}
