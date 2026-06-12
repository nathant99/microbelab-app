import Foundation
import Models

/// View-local state machine for the microbiome simulator UI.
///
/// Per `.claude/rules/state-machines.md` § `*Machine` Structs. Holds the
/// current snapshot + history-for-undo + UI flags. Pure value type.
public nonisolated struct SimulationMachine: Sendable, Equatable {
    public var state: MicrobiomeState
    /// Stack of prior states for the in-session undo affordance. Bounded so
    /// memory doesn't grow unbounded across long sessions.
    public var history: [MicrobiomeState]
    public var historyLimit: Int
    public var showingFeedingPicker: Bool
    public var showingAntibioticConfirmation: Bool

    public init(
        state: MicrobiomeState = .empty(),
        history: [MicrobiomeState] = [],
        historyLimit: Int = 32,
        showingFeedingPicker: Bool = false,
        showingAntibioticConfirmation: Bool = false
    ) {
        self.state = state
        self.history = history
        self.historyLimit = historyLimit
        self.showingFeedingPicker = showingFeedingPicker
        self.showingAntibioticConfirmation = showingAntibioticConfirmation
    }

    public mutating func reset() {
        self = SimulationMachine()
    }

    public mutating func advance(using simulator: MicrobiomeSimulator) {
        pushHistory()
        state = simulator.tick(state)
    }

    public mutating func setFeedingMode(_ mode: FeedingMode) {
        pushHistory()
        state = MicrobiomeState(
            populations: state.populations,
            feedingMode: mode,
            antibioticState: state.antibioticState,
            tickCount: state.tickCount,
            activeSlot: state.activeSlot
        )
        showingFeedingPicker = false
    }

    public mutating func triggerAntibiotic(daysActive: Int = 3) {
        pushHistory()
        state = MicrobiomeState(
            populations: state.populations,
            feedingMode: state.feedingMode,
            antibioticState: .active(daysLeft: daysActive),
            tickCount: state.tickCount,
            activeSlot: state.activeSlot
        )
        showingAntibioticConfirmation = false
    }

    public mutating func undo() {
        guard let previous = history.popLast() else { return }
        state = previous
    }

    private mutating func pushHistory() {
        history.append(state)
        if history.count > historyLimit {
            history.removeFirst(history.count - historyLimit)
        }
    }
}
