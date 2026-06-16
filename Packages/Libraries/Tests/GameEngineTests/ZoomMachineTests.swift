import Testing
import ForgeStateMachine
@testable import GameEngine
@testable import Models

@Suite("ZoomMachine")
nonisolated struct ZoomMachineTests {
    @Test func startsAtUnaided() {
        let machine = ZoomMachine()
        #expect(machine.currentTier == .unaided)
        #expect(machine.inTierProgress == 0)
        #expect(machine.pendingTransition == nil)
    }

    @Test("conforms to ForgeStateMachine.ViewMachine — protocol-witness `init()` + `reset()` resolve cleanly")
    func conformsToViewMachine() {
        // Compile-time check: any local that satisfies the ViewMachine
        // protocol witness can be constructed via `init()` and reset via
        // `mutating func reset()`. If the protocol witness ever drifted
        // (e.g., the zero-arg init was deleted), this would fail to compile.
        func acceptViewMachine<M: ViewMachine>(_ machine: inout M) {
            machine.reset()
        }
        var m = ZoomMachine(currentTier: .light, inTierProgress: 0.5)
        acceptViewMachine(&m)
        #expect(m.currentTier == .unaided)
        #expect(m.inTierProgress == 0)
        #expect(m.pendingTransition == nil)
    }

    @Test func pinchInClimbsTiers() {
        var machine = ZoomMachine()
        machine.applyPinch(delta: 1.5)
        #expect(machine.currentTier == .light)
        #expect(machine.pendingTransition == .zoomingIn(from: .unaided, to: .light))
    }

    @Test func consumeTransitionClears() {
        var machine = ZoomMachine()
        machine.applyPinch(delta: 1.5)
        machine.consumeTransition()
        #expect(machine.pendingTransition == nil)
    }

    @Test func pinchOutAtUnaidedIsClamped() {
        var machine = ZoomMachine()
        machine.applyPinch(delta: -2.0)
        #expect(machine.currentTier == .unaided)
        #expect(machine.inTierProgress == 0)
    }

    @Test func snapJumpsAndSetsTransition() {
        var machine = ZoomMachine()
        machine.snap(to: .electron)
        #expect(machine.currentTier == .electron)
        #expect(machine.pendingTransition == .zoomingIn(from: .unaided, to: .electron))
    }

    @Test func resetReturnsToBaseline() {
        var machine = ZoomMachine(currentTier: .electron, inTierProgress: 0.8)
        machine.reset()
        #expect(machine.currentTier == .unaided)
        #expect(machine.inTierProgress == 0)
        #expect(machine.pendingTransition == nil)
    }
}
