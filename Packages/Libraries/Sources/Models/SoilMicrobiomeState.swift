import Foundation

/// Moisture-load equivalent of `FeedingMode` for the soil ecology. The
/// soil microbiome doesn't have a fiber/sugar/balanced surface the way
/// the gut does — its dominant levers are moisture availability (water +
/// air pockets), the periodic compost pulse (fresh organic input), and
/// drought (dehydration that sends most microbes into dormancy while
/// extremophiles persist).
///
/// Mapping to `FeedingMode` for the underlying `MicrobiomeSimulator`:
///
/// | SoilMoistureLoad | FeedingMode |
/// |------------------|-------------|
/// | `.moist`         | `.balanced` |
/// | `.compost`       | `.fiber`    |
/// | `.saturated`     | `.sugar`    |
/// | `.drought`       | `.none`     |
///
/// - **`.moist`** maps to `.balanced` — every guild thrives in moist soil
///   with adequate air pockets. The canonical soil decomposers (Loam) +
///   nitrogen-fixers (Nodu) + thermophiles (Therm) all grow at their
///   default rates.
/// - **`.compost`** maps to `.fiber` — a fresh organic input is the
///   decomposers' favorite feast. Saprophytic fungi (Loam) and other
///   decomposers bloom. Mirrors the gut's fiber semantic (the canonical
///   "good fuel" for the canonical microbes).
/// - **`.saturated`** maps to `.sugar` — too much water displaces air,
///   the aerobic guild dwindles, and only the anaerobic specialists
///   thrive. Mirrors the gut's sugar semantic (some microbes love it,
///   most can't compete).
/// - **`.drought`** maps to `.none` — no fresh input + dehydration sends
///   most microbes into dormancy. Only the extremophiles (Therm
///   thermophiles + Halo halophiles) ride it out.
///
/// **Trauma-informed register per `.claude/rules/trauma-informed-content.md`**:
/// drought and decay are framed as ecology, NEVER as moral judgment or
/// death-anxiety. The mentor copy in `SoilMicrobiomeView` surfaces
/// "everyone slows down" (drought) and "decomposers return material to
/// the soil" (decay) — the framing is participation, not loss. Pedagogy
/// bridge: this is the gateway to bioforge / ecosphere ecology — kids
/// learn soil is a thriving system, not "dirt".
public nonisolated enum SoilMoistureLoad: String, Codable, Sendable, CaseIterable {
    case moist
    case compost
    case saturated
    case drought

    /// Underlying `FeedingMode` the shared `MicrobiomeSimulator` consumes.
    public var feedingMode: FeedingMode {
        switch self {
        case .moist: return .balanced
        case .compost: return .fiber
        case .saturated: return .sugar
        case .drought: return .none
        }
    }

    /// Trauma-informed display label. Kid-readable + warm.
    public var displayName: String {
        switch self {
        case .moist: return "Moist"
        case .compost: return "Compost"
        case .saturated: return "Saturated"
        case .drought: return "Drought"
        }
    }

    /// SF Symbol for the segmented picker.
    public var systemImage: String {
        switch self {
        case .moist: return "humidity.fill"
        case .compost: return "leaf.fill"
        case .saturated: return "drop.triangle.fill"
        case .drought: return "sun.max.fill"
        }
    }
}

/// Snapshot of the soil microbiome simulator at a given tick. Pure value
/// type — wraps a standard `MicrobiomeState` so the underlying engine
/// can run the same population math, and adds a soil-specific surface
/// for the moisture-load lever.
public nonisolated struct SoilMicrobiomeState: Codable, Sendable, Equatable {
    public let underlying: MicrobiomeState
    public let moistureLoad: SoilMoistureLoad

    public init(underlying: MicrobiomeState, moistureLoad: SoilMoistureLoad) {
        self.underlying = underlying
        self.moistureLoad = moistureLoad
    }

    public var tickCount: Int { underlying.tickCount }
    public var totalPopulation: Int { underlying.totalPopulation }

    /// Empty starting state in the `.soil` slot.
    public static var empty: SoilMicrobiomeState {
        SoilMicrobiomeState(
            underlying: .empty(in: .soil),
            moistureLoad: .moist
        )
    }

    /// Per-tick advance of the soil-stable tick run.
    ///
    /// - **`.moist` / `.compost`** (thriving loads) → `prior + 1`. The
    ///   underground is humming; decomposers + nitrogen-fixers +
    ///   extremophiles all participate; the stable run extends.
    /// - **`.saturated`** → `0`. Anaerobic stew displaces the aerobic
    ///   guild; the run resets. (Ecology, NEVER framed as failure — the
    ///   framing of "water has filled every pore" lives in the
    ///   `SoilMicrobiomeView.refreshMentorCue`.)
    /// - **`.drought`** → `prior`. Drought slows everything down;
    ///   extremophiles persist + the rest go dormant. Holding the run
    ///   in place mirrors the kid's lived experience — a drought
    ///   doesn't undo earlier balance, it just pauses growth.
    ///
    /// Load-bearing for the `soilDecomposerWhisperer` achievement
    /// criterion in `SoilMicrobiomeView`. Pure-value derivation so the
    /// threshold logic is unit-testable without a GPU context.
    public static func nextStableRun(prior: Int, moistureLoad: SoilMoistureLoad) -> Int {
        switch moistureLoad {
        case .moist, .compost: return prior + 1
        case .saturated: return 0
        case .drought: return prior
        }
    }
}
