import Foundation
import Testing
@testable import GameEngine
@testable import Models

@Suite("SimulationMachine")
nonisolated struct SimulationMachineTests {
    @Test func startsAtEmptyBalanced() {
        let machine = SimulationMachine()
        #expect(machine.state.tickCount == 0)
        #expect(machine.state.feedingMode == .balanced)
        #expect(machine.history.isEmpty)
    }

    @Test func setFeedingModeChangesMode() {
        var machine = SimulationMachine()
        machine.setFeedingMode(.fiber)
        #expect(machine.state.feedingMode == .fiber)
        #expect(machine.history.count == 1)
        #expect(machine.showingFeedingPicker == false)
    }

    @Test func undoRestoresPreviousState() {
        var machine = SimulationMachine()
        machine.setFeedingMode(.fiber)
        machine.setFeedingMode(.sugar)
        machine.undo()
        #expect(machine.state.feedingMode == .fiber)
    }

    @Test func historyIsBounded() {
        var machine = SimulationMachine(historyLimit: 3)
        for mode in [FeedingMode.fiber, .sugar, .balanced, .none, .fiber] {
            machine.setFeedingMode(mode)
        }
        #expect(machine.history.count <= 3)
    }

    @Test func resetClearsAllState() {
        var machine = SimulationMachine()
        machine.setFeedingMode(.fiber)
        machine.triggerAntibiotic()
        machine.reset()
        #expect(machine.state.feedingMode == .balanced)
        #expect(machine.state.antibioticState == .none)
        #expect(machine.history.isEmpty)
    }
}
