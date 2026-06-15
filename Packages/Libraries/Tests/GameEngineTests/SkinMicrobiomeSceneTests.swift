import Foundation
import Testing
@testable import GameEngine
@testable import Models

@Suite("SkinMicrobiomeScene")
@MainActor
final class SkinMicrobiomeSceneTests {
    nonisolated deinit {}

    private func skinFixture() -> [MicrobeCharacter] {
        // Two skin microbes: Sebu (sebum commensal) + Guard (defensin-
        // producing commensal). Stand-in for the catalog filter so the
        // unit test runs without loading the bundled JSON.
        [
            MicrobeCharacter(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000020")!,
                slug: "sebu",
                displayName: "Sebu",
                kingdom: .bacteria,
                role: .beneficial,
                preferredEnvironment: .skin,
                growthRate: GrowthRate(onFiber: 0.2, onSugar: 0.5, onBalanced: 0.4, onNone: -0.2),
                catchphrase: "I keep the skin oils in balance.",
                factCard: "Cutibacterium-style sebum commensal.",
                firstKit: 7
            ),
            MicrobeCharacter(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
                slug: "guard",
                displayName: "Guard",
                kingdom: .bacteria,
                role: .beneficial,
                preferredEnvironment: .skin,
                growthRate: GrowthRate(onFiber: 0.3, onSugar: 0.1, onBalanced: 0.4, onNone: -0.1),
                catchphrase: "I keep the neighborhood steady.",
                factCard: "Defensin-producing commensal.",
                firstKit: 1
            )
        ]
    }

    @Test func initialStateIsEmptyAndInSkinSlot() {
        let scene = SkinMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: skinFixture())
        )
        #expect(scene.state == .empty)
        #expect(scene.state.underlying.activeSlot == .skin)
        #expect(scene.state.careLoad == .gentleWash)
        #expect(scene.state.tickCount == 0)
    }

    @Test func setCareLoadUpdatesUnderlyingFeedingMode() {
        let scene = SkinMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: skinFixture())
        )
        scene.setCareLoad(.scratch)
        #expect(scene.state.careLoad == .scratch)
        #expect(scene.state.underlying.feedingMode == .sugar)

        scene.setCareLoad(.restRecover)
        #expect(scene.state.careLoad == .restRecover)
        #expect(scene.state.underlying.feedingMode == .none)
    }

    @Test func advanceOneTickBumpsTickCount() {
        let scene = SkinMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: skinFixture())
        )
        scene.setCareLoad(.gentleWash)
        scene.advanceOneTick()
        #expect(scene.state.tickCount == 1)
        scene.advanceOneTick()
        #expect(scene.state.tickCount == 2)
    }

    @Test func undoRestoresPreviousState() {
        let scene = SkinMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: skinFixture())
        )
        scene.setCareLoad(.barrier)
        scene.advanceOneTick()
        let priorState = scene.state
        scene.advanceOneTick()
        #expect(scene.state != priorState)
        scene.undo()
        #expect(scene.state == priorState)
    }

    @Test func resetClearsStateAndHistory() {
        let scene = SkinMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: skinFixture())
        )
        scene.setCareLoad(.scratch)
        scene.advanceOneTick()
        scene.advanceOneTick()
        scene.reset()
        #expect(scene.state == .empty)
        #expect(scene.state.tickCount == 0)
        #expect(scene.history.isEmpty)
    }

    @Test func historyIsBoundedByLimit() {
        let scene = SkinMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: skinFixture()),
            historyLimit: 4
        )
        for _ in 0..<10 {
            scene.advanceOneTick()
        }
        #expect(scene.history.count <= 4)
    }

    @Test func restRecoverCollapsesGrowthOverTicks() {
        // Trauma-informed pedagogy verification: rest maps to .none feeding
        // mode, so growth slows / dwindles. The kid sees "rest lets the
        // garden settle" — never the punitive framing "you didn't do
        // anything so nothing happened".
        let microbes = skinFixture()
        let scene = SkinMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: microbes)
        )
        // Bloom first via scratch (disturbance favors flora)
        scene.setCareLoad(.scratch)
        for _ in 0..<3 { scene.advanceOneTick() }
        let bloomTotal = scene.state.totalPopulation

        // Now rest + tick several times
        scene.setCareLoad(.restRecover)
        for _ in 0..<5 { scene.advanceOneTick() }
        let afterRest = scene.state.totalPopulation

        // Rest should not grow the neighborhood beyond the scratch bloom.
        #expect(afterRest <= bloomTotal + 1,
                "Rest should not grow the garden beyond the scratch bloom")
    }
}
