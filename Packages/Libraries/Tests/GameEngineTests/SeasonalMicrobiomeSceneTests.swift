import Foundation
import Testing
@testable import GameEngine
@testable import Models

@Suite("SeasonalMicrobiomeScene")
@MainActor
final class SeasonalMicrobiomeSceneTests {
    nonisolated deinit {}

    private func seasonalFixture() -> [MicrobeCharacter] {
        // Two gut-relevant microbes: one fiber-loving (Bifido-style) and one
        // sugar-loving (Yeast-style). Mirrors the per-ecology scenes' minimal
        // 2-microbe fixture pattern from OralMicrobiomeSceneTests.
        [
            MicrobeCharacter(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000020")!,
                slug: "bifido",
                displayName: "Bifido",
                kingdom: .bacteria,
                role: .beneficial,
                preferredEnvironment: .largeIntestine,
                growthRate: GrowthRate(onFiber: 0.6, onSugar: 0.1, onBalanced: 0.4, onNone: -0.2),
                catchphrase: "Fiber, please.",
                factCard: "Bifidobacterium-style gut commensal.",
                firstKit: 1
            ),
            MicrobeCharacter(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
                slug: "yeast",
                displayName: "Yeast",
                kingdom: .fungi,
                role: .opportunistic,
                preferredEnvironment: .largeIntestine,
                growthRate: GrowthRate(onFiber: 0.1, onSugar: 0.7, onBalanced: 0.2, onNone: -0.3),
                catchphrase: "I bloom on sugar.",
                factCard: "Yeast-style gut opportunist.",
                firstKit: 2
            )
        ]
    }

    @Test func initialStateIsEmptyAndInLargeIntestine() {
        let scene = SeasonalMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: seasonalFixture())
        )
        #expect(scene.state == .empty)
        #expect(scene.state.underlying.activeSlot == .largeIntestine)
        #expect(scene.state.load == .winterCold)
        #expect(scene.state.tickCount == 0)
        #expect(scene.stableRun == 0)
    }

    @Test func setLoadUpdatesUnderlyingFeedingMode() {
        let scene = SeasonalMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: seasonalFixture())
        )
        scene.setLoad(.springAllergy)
        #expect(scene.state.load == .springAllergy)
        #expect(scene.state.underlying.feedingMode == .sugar)

        scene.setLoad(.summerWarm)
        #expect(scene.state.load == .summerWarm)
        #expect(scene.state.underlying.feedingMode == .fiber)

        scene.setLoad(.autumnSettle)
        #expect(scene.state.load == .autumnSettle)
        #expect(scene.state.underlying.feedingMode == .none)
    }

    @Test func advanceOneTickBumpsTickCount() {
        let scene = SeasonalMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: seasonalFixture())
        )
        scene.setLoad(.summerWarm)
        scene.advanceOneTick()
        #expect(scene.state.tickCount == 1)
        scene.advanceOneTick()
        #expect(scene.state.tickCount == 2)
    }

    @Test func winterColdAdvancesStableRun() {
        let scene = SeasonalMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: seasonalFixture())
        )
        scene.setLoad(.winterCold)
        scene.advanceOneTick()
        scene.advanceOneTick()
        scene.advanceOneTick()
        #expect(scene.stableRun == 3)
    }

    @Test func springAllergyResetsStableRun() {
        // Per `SeasonalMicrobiomeState.nextStableRun(prior:load:)` doc-comment:
        // spring allergy resets the run because the IgE response surfaces +
        // the gut community shifts. Resetting is NOT shame; allergy is
        // sensory not moral. Trauma-informed posture pinned by this test.
        let scene = SeasonalMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: seasonalFixture())
        )
        scene.setLoad(.winterCold)
        scene.advanceOneTick()
        scene.advanceOneTick()
        #expect(scene.stableRun == 2)
        scene.setLoad(.springAllergy)
        scene.advanceOneTick()
        #expect(scene.stableRun == 0)
    }

    @Test func autumnSettleHoldsStableRun() {
        // Per doc-comment: autumn-settle holds the run in place (community
        // settles; not progress, not regression).
        let scene = SeasonalMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: seasonalFixture())
        )
        scene.setLoad(.summerWarm)
        scene.advanceOneTick()
        scene.advanceOneTick()
        #expect(scene.stableRun == 2)
        scene.setLoad(.autumnSettle)
        scene.advanceOneTick()
        scene.advanceOneTick()
        #expect(scene.stableRun == 2)
    }

    @Test func summerWarmTickGrowsBifido() {
        let microbes = seasonalFixture()
        let scene = SeasonalMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: microbes)
        )
        scene.setLoad(.summerWarm)
        scene.advanceOneTick()
        let bifidoID = microbes[0].id
        let bifidoPop = scene.state.underlying.populations[bifidoID] ?? 0
        // Fiber feeding (mapped from summerWarm) seeds Bifido per the
        // simulator's seed-from-zero rule (fiber modifier 0.6 > 0.2 threshold).
        #expect(bifidoPop > 0,
                "Bifido should bloom on the first summer-warm tick (fiber-driven seed)")
    }

    @Test func undoRestoresPreviousState() {
        let scene = SeasonalMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: seasonalFixture())
        )
        scene.setLoad(.summerWarm)
        scene.advanceOneTick()
        let priorState = scene.state
        scene.advanceOneTick()
        #expect(scene.state != priorState)
        scene.undo()
        #expect(scene.state == priorState)
    }

    @Test func resetClearsStateAndHistoryAndStableRun() {
        let scene = SeasonalMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: seasonalFixture())
        )
        scene.setLoad(.winterCold)
        scene.advanceOneTick()
        scene.advanceOneTick()
        scene.reset()
        #expect(scene.state == .empty)
        #expect(scene.state.tickCount == 0)
        #expect(scene.history.isEmpty)
        #expect(scene.stableRun == 0)
    }

    @Test func historyIsBoundedByLimit() {
        let scene = SeasonalMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: seasonalFixture()),
            historyLimit: 4
        )
        for _ in 0..<10 {
            scene.advanceOneTick()
        }
        #expect(scene.history.count <= 4)
    }
}
