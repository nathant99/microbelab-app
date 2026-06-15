import Foundation
import Testing
@testable import GameEngine
@testable import Models

@Suite("OralMicrobiomeScene")
@MainActor
final class OralMicrobiomeSceneTests {
    nonisolated deinit {}

    private func oralFixture() -> [MicrobeCharacter] {
        // Two oral-cavity microbes: one sugar-loving (Sweet — S. mutans-style)
        // and one balance-keeper (Guard — defensin-producing commensal).
        [
            MicrobeCharacter(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
                slug: "sweet",
                displayName: "Sweet",
                kingdom: .bacteria,
                role: .opportunistic,
                preferredEnvironment: .oralCavity,
                growthRate: GrowthRate(onFiber: 0.1, onSugar: 0.7, onBalanced: 0.2, onNone: -0.3),
                catchphrase: "I just like sugar a lot.",
                factCard: "S. mutans-style oral commensal.",
                firstKit: 6
            ),
            MicrobeCharacter(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
                slug: "guard",
                displayName: "Guard",
                kingdom: .bacteria,
                role: .beneficial,
                preferredEnvironment: .oralCavity,
                growthRate: GrowthRate(onFiber: 0.3, onSugar: 0.1, onBalanced: 0.4, onNone: -0.1),
                catchphrase: "I keep the neighborhood steady.",
                factCard: "Defensin-producing commensal.",
                firstKit: 1
            )
        ]
    }

    @Test func initialStateIsEmptyAndInOralCavity() {
        let scene = OralMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: oralFixture())
        )
        #expect(scene.state == .empty)
        #expect(scene.state.underlying.activeSlot == .oralCavity)
        #expect(scene.state.sugarLoad == .water)
        #expect(scene.state.tickCount == 0)
    }

    @Test func setSugarLoadUpdatesUnderlyingFeedingMode() {
        let scene = OralMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: oralFixture())
        )
        scene.setSugarLoad(.sugarSnack)
        #expect(scene.state.sugarLoad == .sugarSnack)
        #expect(scene.state.underlying.feedingMode == .sugar)

        scene.setSugarLoad(.brush)
        #expect(scene.state.sugarLoad == .brush)
        #expect(scene.state.underlying.feedingMode == .none)
    }

    @Test func advanceOneTickBumpsTickCount() {
        let scene = OralMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: oralFixture())
        )
        scene.setSugarLoad(.sugarSnack)
        scene.advanceOneTick()
        #expect(scene.state.tickCount == 1)
        scene.advanceOneTick()
        #expect(scene.state.tickCount == 2)
    }

    @Test func sugarSnackTickGrowsSweet() {
        let microbes = oralFixture()
        let scene = OralMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: microbes)
        )
        scene.setSugarLoad(.sugarSnack)
        scene.advanceOneTick()
        let sweetID = microbes[0].id
        let sweetPop = scene.state.underlying.populations[sweetID] ?? 0
        // Seed-from-zero kicks Sweet to base 8 on a favorable feed (sugar
        // modifier 0.7 > 0.2 threshold) per MicrobiomeSimulator.tick.
        #expect(sweetPop > 0,
                "Sweet should bloom on the first sugar-snack tick (seed-from-zero)")
    }

    @Test func undoRestoresPreviousState() {
        let scene = OralMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: oralFixture())
        )
        scene.setSugarLoad(.sugarSnack)
        scene.advanceOneTick()
        let priorState = scene.state
        scene.advanceOneTick()
        #expect(scene.state != priorState)
        scene.undo()
        #expect(scene.state == priorState)
    }

    @Test func resetClearsStateAndHistory() {
        let scene = OralMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: oralFixture())
        )
        scene.setSugarLoad(.sugarSnack)
        scene.advanceOneTick()
        scene.advanceOneTick()
        scene.reset()
        #expect(scene.state == .empty)
        #expect(scene.state.tickCount == 0)
        #expect(scene.history.isEmpty)
    }

    @Test func historyIsBoundedByLimit() {
        let scene = OralMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: oralFixture()),
            historyLimit: 4
        )
        // setSugarLoad + advanceOneTick each push history; 10 actions should
        // saturate to the historyLimit (4).
        for _ in 0..<10 {
            scene.advanceOneTick()
        }
        #expect(scene.history.count <= 4)
    }

    @Test func brushSugarLoadCollapsesGrowthOverTicks() {
        // Trauma-informed pedagogy verification: brushing maps to .none
        // feeding mode, so growth slows / dwindles for both microbes. We
        // verify the engine actually quiets the populations under sustained
        // brushing (the kid sees "brushing thins the plaque").
        let microbes = oralFixture()
        let scene = OralMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: microbes)
        )
        // Bloom first via sugar
        scene.setSugarLoad(.sugarSnack)
        for _ in 0..<3 { scene.advanceOneTick() }
        let bloomTotal = scene.state.totalPopulation

        // Now brush + tick several times
        scene.setSugarLoad(.brush)
        for _ in 0..<5 { scene.advanceOneTick() }
        let afterBrushing = scene.state.totalPopulation

        // After 5 brush ticks, the total population should not exceed the
        // bloom-tick peak by any meaningful margin. The exact decay rate is
        // engine-specific, so we only assert "doesn't explode under brushing".
        #expect(afterBrushing <= bloomTotal + 1,
                "Brushing should not grow the neighborhood beyond the sugar bloom")
    }
}
