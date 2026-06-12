import Testing
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
