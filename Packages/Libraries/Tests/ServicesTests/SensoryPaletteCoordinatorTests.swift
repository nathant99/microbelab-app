import Testing
import Foundation
import ForgeSensory
@testable import Services

@Suite("SensoryPaletteCoordinator") @MainActor
struct SensoryPaletteCoordinatorTests {

    @Test("init defaults to empty event + zero count")
    func initDefaults() {
        let coordinator = SensoryPaletteCoordinator()
        #expect(coordinator.lastEvent == nil)
        #expect(coordinator.firedCount == 0)
    }

    @Test("fire mirrors the event into lastEvent")
    func fireMirrorsEvent() {
        let coordinator = SensoryPaletteCoordinator()
        coordinator.fire(.correctAnswer)
        #expect(coordinator.lastEvent == .correctAnswer)
        coordinator.fire(.incorrectAnswer)
        #expect(coordinator.lastEvent == .incorrectAnswer)
    }

    @Test("fire increments firedCount monotonically")
    func firedCountMonotonic() {
        let coordinator = SensoryPaletteCoordinator()
        coordinator.fire(.correctAnswer)
        #expect(coordinator.firedCount == 1)
        coordinator.fire(.achievement)
        #expect(coordinator.firedCount == 2)
        coordinator.fire(.challengeComplete)
        #expect(coordinator.firedCount == 3)
    }

    @Test("fire handles streakMilestone associated value")
    func fireHandlesAssociatedValue() {
        let coordinator = SensoryPaletteCoordinator()
        coordinator.fire(.streakMilestone(3))
        #expect(coordinator.lastEvent == .streakMilestone(3))
        coordinator.fire(.streakMilestone(5))
        // The associated value flows through unmodified — useful when the
        // ImmuneGameView pipes the wave index as the milestone payload.
        #expect(coordinator.lastEvent == .streakMilestone(5))
    }

    @Test("fire handles mascotReaction mood payload")
    func fireHandlesMascotReaction() {
        let coordinator = SensoryPaletteCoordinator()
        coordinator.fire(.mascotReaction(.excited))
        #expect(coordinator.lastEvent == .mascotReaction(.excited))
    }

    @Test("two coordinators stay independent")
    func twoCoordinatorsIndependent() {
        // Defensive: the Sensible class wraps a private ForgeSensory.SensoryPalette
        // instance; verify the static state isn't accidentally shared.
        let a = SensoryPaletteCoordinator()
        let b = SensoryPaletteCoordinator()
        a.fire(.correctAnswer)
        #expect(a.firedCount == 1)
        #expect(b.firedCount == 0)
        #expect(a.lastEvent == .correctAnswer)
        #expect(b.lastEvent == nil)
    }
}
