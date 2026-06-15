import Foundation
import Testing
@testable import GameEngine
@testable import Models

@Suite("SoilMicrobiomeScene")
@MainActor
final class SoilMicrobiomeSceneTests {
    nonisolated deinit {}

    private func soilFixture() -> [MicrobeCharacter] {
        // Two soil microbes: Loam (saprophytic decomposer fungi — bloom
        // on fiber/compost) + Nodu (Rhizobium nitrogen-fixer — thrives
        // in balanced soil with adequate air pockets).
        [
            MicrobeCharacter(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000030")!,
                slug: "loam",
                displayName: "Loam",
                kingdom: .fungi,
                role: .beneficial,
                preferredEnvironment: .soil,
                growthRate: GrowthRate(onFiber: 0.7, onSugar: 0.1, onBalanced: 0.4, onNone: -0.3),
                catchphrase: "I return material to the soil.",
                factCard: "Saprophytic decomposer fungi.",
                firstKit: 8
            ),
            MicrobeCharacter(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000031")!,
                slug: "nodu",
                displayName: "Nodu",
                kingdom: .bacteria,
                role: .beneficial,
                preferredEnvironment: .soil,
                growthRate: GrowthRate(onFiber: 0.4, onSugar: 0.0, onBalanced: 0.5, onNone: -0.2),
                catchphrase: "I feed plants their main element.",
                factCard: "Rhizobium nitrogen-fixer.",
                firstKit: 8
            )
        ]
    }

    @Test func initialStateIsEmptyAndInSoilSlot() {
        let scene = SoilMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: soilFixture())
        )
        #expect(scene.state == .empty)
        #expect(scene.state.underlying.activeSlot == .soil)
        #expect(scene.state.moistureLoad == .moist)
        #expect(scene.state.tickCount == 0)
    }

    @Test func setMoistureLoadUpdatesUnderlyingFeedingMode() {
        let scene = SoilMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: soilFixture())
        )
        scene.setMoistureLoad(.compost)
        #expect(scene.state.moistureLoad == .compost)
        #expect(scene.state.underlying.feedingMode == .fiber)

        scene.setMoistureLoad(.drought)
        #expect(scene.state.moistureLoad == .drought)
        #expect(scene.state.underlying.feedingMode == .none)
    }

    @Test func advanceOneTickBumpsTickCount() {
        let scene = SoilMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: soilFixture())
        )
        scene.setMoistureLoad(.compost)
        scene.advanceOneTick()
        #expect(scene.state.tickCount == 1)
        scene.advanceOneTick()
        #expect(scene.state.tickCount == 2)
    }

    @Test func compostTickGrowsLoam() {
        let microbes = soilFixture()
        let scene = SoilMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: microbes)
        )
        scene.setMoistureLoad(.compost)
        scene.advanceOneTick()
        let loamID = microbes[0].id
        let loamPop = scene.state.underlying.populations[loamID] ?? 0
        #expect(loamPop > 0,
                "Loam should bloom on the first compost tick (favorable fiber feed)")
    }

    @Test func undoRestoresPreviousState() {
        let scene = SoilMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: soilFixture())
        )
        scene.setMoistureLoad(.compost)
        scene.advanceOneTick()
        let priorState = scene.state
        scene.advanceOneTick()
        #expect(scene.state != priorState)
        scene.undo()
        #expect(scene.state == priorState)
    }

    @Test func resetClearsStateAndHistory() {
        let scene = SoilMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: soilFixture())
        )
        scene.setMoistureLoad(.compost)
        scene.advanceOneTick()
        scene.advanceOneTick()
        scene.reset()
        #expect(scene.state == .empty)
        #expect(scene.state.tickCount == 0)
        #expect(scene.history.isEmpty)
    }

    @Test func historyIsBoundedByLimit() {
        let scene = SoilMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: soilFixture()),
            historyLimit: 4
        )
        for _ in 0..<10 {
            scene.advanceOneTick()
        }
        #expect(scene.history.count <= 4)
    }

    @Test func droughtCollapsesGrowthOverTicks() {
        // Trauma-informed pedagogy verification: drought maps to .none
        // feeding mode, so growth slows / dwindles. The kid sees
        // "everyone slows down" — never the catastrophe framing.
        let microbes = soilFixture()
        let scene = SoilMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: MicrobiomeSimulator(microbes: microbes)
        )
        // Bloom first via compost
        scene.setMoistureLoad(.compost)
        for _ in 0..<3 { scene.advanceOneTick() }
        let bloomTotal = scene.state.totalPopulation

        // Now drought + tick several times
        scene.setMoistureLoad(.drought)
        for _ in 0..<5 { scene.advanceOneTick() }
        let afterDrought = scene.state.totalPopulation

        // Drought should not grow the underground beyond the compost bloom.
        #expect(afterDrought <= bloomTotal + 1,
                "Drought should not grow the underground beyond the compost bloom")
    }
}
