import Foundation

/// Feeding mode the player picks for the gut. Each mode applies a per-microbe
/// growth-rate modifier (see `MicrobeCharacter.growthRate`).
public nonisolated enum FeedingMode: String, Codable, Sendable, CaseIterable {
    case fiber
    case sugar
    case balanced
    case none
}

/// Antibiotic shock state — discrete event with bounded recovery curve.
public nonisolated enum AntibioticState: Codable, Sendable, Equatable {
    case none
    case active(daysLeft: Int)
    case recovering(ticksLeft: Int)

    public var isPerturbing: Bool {
        switch self {
        case .none: return false
        case .active, .recovering: return true
        }
    }
}

/// Snapshot of the microbiome simulator at a given tick. Pure value type —
/// the simulator returns a new state per tick rather than mutating in place,
/// per `.claude/rules/state-machines.md` § Side effects in transitions.
public nonisolated struct MicrobiomeState: Codable, Sendable, Equatable {
    /// Populations keyed by `MicrobeCharacter.id`. Integer count for
    /// determinism + easy JSON round-tripping.
    public let populations: [UUID: Int]
    public let feedingMode: FeedingMode
    public let antibioticState: AntibioticState
    public let tickCount: Int
    /// Per-slot ecology label surfaced in the simulator HUD.
    public let activeSlot: GutSlot

    public init(
        populations: [UUID: Int],
        feedingMode: FeedingMode,
        antibioticState: AntibioticState,
        tickCount: Int,
        activeSlot: GutSlot
    ) {
        self.populations = populations
        self.feedingMode = feedingMode
        self.antibioticState = antibioticState
        self.tickCount = tickCount
        self.activeSlot = activeSlot
    }

    /// Convenience: total microbe count across all populations.
    public var totalPopulation: Int {
        populations.values.reduce(0, +)
    }

    /// Empty starting state for a new session.
    public static func empty(in slot: GutSlot = .colon) -> MicrobiomeState {
        MicrobiomeState(
            populations: [:],
            feedingMode: .balanced,
            antibioticState: .none,
            tickCount: 0,
            activeSlot: slot
        )
    }
}
