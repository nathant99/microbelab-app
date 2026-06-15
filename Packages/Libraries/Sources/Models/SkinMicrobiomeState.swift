import Foundation

/// Care-load equivalent of `FeedingMode` for the skin ecology. The skin
/// microbiome doesn't have a fiber/sugar/balanced surface the way the gut
/// does — its dominant levers are gentle care (washing + barrier oils) vs.
/// disruption (scratching when itchy) vs. recovery time.
///
/// Mapping to `FeedingMode` for the underlying `MicrobiomeSimulator`:
///
/// | SkinCareLoad   | FeedingMode |
/// |----------------|-------------|
/// | `.gentleWash`  | `.balanced` |
/// | `.barrier`     | `.balanced` |
/// | `.scratch`     | `.sugar`    |
/// | `.restRecover` | `.none`     |
///
/// `.scratch` maps to `.sugar` because scratching jumbles the flora — the
/// opportunistic neighbors that prefer disturbance get a foothold; the
/// canonical commensals (Sebu / Demi / Guard) take a step back. The
/// simulator's `.sugar` modifier already encodes "uneven growth toward
/// disturbance-tolerant microbes" without inventing new growth-rate math.
///
/// `.restRecover` maps to `.none` because giving the skin time = no
/// disturbance and no fresh input. Mirrors the engine's "the community
/// settles" register.
///
/// **Trauma-informed register per `.claude/rules/trauma-informed-content.md`**:
/// scratching is acknowledged as something the kid sometimes does when
/// itchy — NEVER framed as "you shouldn't scratch" or "you ruined the
/// skin community". The `.scratch` state surfaces "the skin gets itchy —
/// the neighborhood gets jumbled" copy; the predicate that resets the
/// stable-run counter is ecology, not blame. Eczema-safe: no clinical-
/// judgment vocabulary anywhere on the surface.
public nonisolated enum SkinCareLoad: String, Codable, Sendable, CaseIterable {
    case gentleWash
    case barrier
    case scratch
    case restRecover

    /// Underlying `FeedingMode` the shared `MicrobiomeSimulator` consumes.
    public var feedingMode: FeedingMode {
        switch self {
        case .gentleWash, .barrier: return .balanced
        case .scratch: return .sugar
        case .restRecover: return .none
        }
    }

    /// Trauma-informed display label. Kid-readable + warm.
    public var displayName: String {
        switch self {
        case .gentleWash: return "Gentle wash"
        case .barrier: return "Moisturize"
        case .scratch: return "Itchy day"
        case .restRecover: return "Rest"
        }
    }

    /// SF Symbol for the segmented picker.
    public var systemImage: String {
        switch self {
        case .gentleWash: return "drop.circle.fill"
        case .barrier: return "shield.lefthalf.filled"
        case .scratch: return "hand.point.up.left.fill"
        case .restRecover: return "moon.zzz.fill"
        }
    }
}

/// Snapshot of the skin-cavity microbiome simulator at a given tick. Pure
/// value type — wraps a standard `MicrobiomeState` so the underlying engine
/// can run the same population math, and adds a skin-specific surface for
/// the care-load lever.
public nonisolated struct SkinMicrobiomeState: Codable, Sendable, Equatable {
    public let underlying: MicrobiomeState
    public let careLoad: SkinCareLoad

    public init(underlying: MicrobiomeState, careLoad: SkinCareLoad) {
        self.underlying = underlying
        self.careLoad = careLoad
    }

    public var tickCount: Int { underlying.tickCount }
    public var totalPopulation: Int { underlying.totalPopulation }

    /// Empty starting state in the `.skin` slot.
    public static var empty: SkinMicrobiomeState {
        SkinMicrobiomeState(
            underlying: .empty(in: .skin),
            careLoad: .gentleWash
        )
    }

    /// Per-tick advance of the skin-stable tick run.
    ///
    /// - **`.gentleWash` / `.barrier`** (gentle loads) → `prior + 1`. The
    ///   skin garden is holding balance; the stable run extends.
    /// - **`.scratch`** → `0`. Itchy disturbance jumbles the flora; the
    ///   run resets. (Resetting is ecology, NEVER framed as moral failure —
    ///   the per-load mentor copy frames it as "the skin gets itchy".)
    /// - **`.restRecover`** → `prior`. Rest is care, not progress; holding
    ///   the run in place mirrors the kid's lived experience.
    ///
    /// Load-bearing for the `skinKindnessChampion` achievement criterion
    /// in `SkinMicrobiomeView`. Pure-value derivation so the threshold
    /// logic is unit-testable without a GPU context.
    public static func nextStableRun(prior: Int, careLoad: SkinCareLoad) -> Int {
        switch careLoad {
        case .gentleWash, .barrier: return prior + 1
        case .scratch: return 0
        case .restRecover: return prior
        }
    }
}
