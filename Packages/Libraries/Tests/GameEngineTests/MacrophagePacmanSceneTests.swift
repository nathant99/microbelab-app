import Foundation
import Testing
import SpriteKit
@testable import GameEngine
@testable import Models

@Suite("MacrophagePacmanScene")
@MainActor
struct MacrophagePacmanSceneTests {
    // The scene's logic-only surface is testable without GPU per
    // `.claude/rules/spritekit.md` § Lazy Visual Setup — we never call
    // `didMove(to:)` (which would trigger child node creation), so SPM unit
    // tests work without a GPU context.

    private func makeScene() -> MacrophagePacmanScene {
        MacrophagePacmanScene(size: CGSize(width: 400, height: 600))
    }

    @Test func startsAtWaveOne() {
        let scene = makeScene()
        #expect(scene.wave == 1)
        #expect(scene.score == 0)
        #expect(scene.isComplete == false)
    }

    @Test func recordConsumeAccumulatesScore() {
        let scene = makeScene()
        scene.recordConsume(value: 10)
        scene.recordConsume(value: 5)
        #expect(scene.score == 15)
    }

    @Test func clearWaveAdvances() {
        let scene = makeScene()
        let done = scene.clearWave()
        #expect(done == false)
        #expect(scene.wave == 2)
    }

    @Test func clearingAllWavesCompletes() {
        let scene = makeScene()
        for _ in 0..<5 {
            _ = scene.clearWave()
        }
        #expect(scene.isComplete == true)
    }

    @Test func resetRestoresInitialState() {
        let scene = makeScene()
        scene.recordConsume(value: 50)
        _ = scene.clearWave()
        scene.reset()
        #expect(scene.wave == 1)
        #expect(scene.score == 0)
        #expect(scene.isComplete == false)
    }

    // MARK: - Pathogen + macrophage logic

    @Test func spawnSeedsExpectedCount() {
        let scene = MacrophagePacmanScene(
            size: CGSize(width: 400, height: 600),
            totalWaves: 5,
            wavePathogenCounts: [4, 6, 8, 10, 12],
            seed: 1
        )
        scene.spawnCurrentWave()
        #expect(scene.pathogens.count == 4)
        _ = scene.clearWave()
        scene.spawnCurrentWave()
        #expect(scene.pathogens.count == 6)
    }

    @Test func spawnIsReproducibleAcrossSeeds() {
        let lhs = MacrophagePacmanScene(size: CGSize(width: 400, height: 600), seed: 42)
        let rhs = MacrophagePacmanScene(size: CGSize(width: 400, height: 600), seed: 42)
        lhs.spawnCurrentWave()
        rhs.spawnCurrentWave()
        #expect(lhs.pathogens == rhs.pathogens)
    }

    @Test func advancePathogensBouncesOffBounds() {
        let scene = MacrophagePacmanScene(size: CGSize(width: 100, height: 100))
        // Manually plant one pathogen heading rightward off-edge.
        scene.spawnCurrentWave()
        scene.advancePathogens(by: 10) // big delta to ensure several bounces
        for pathogen in scene.pathogens {
            #expect(pathogen.position.x >= 0 && pathogen.position.x <= 100)
            #expect(pathogen.position.y >= 0 && pathogen.position.y <= 100)
        }
    }

    @Test func moveMacrophageClampsToScene() {
        let scene = makeScene()
        scene.moveMacrophage(by: Vec2(x: 100_000, y: 100_000))
        #expect(scene.macrophage.position.x <= Double(scene.size.width))
        #expect(scene.macrophage.position.y <= Double(scene.size.height))
        scene.moveMacrophage(by: Vec2(x: -100_000, y: -100_000))
        #expect(scene.macrophage.position.x == 0)
        #expect(scene.macrophage.position.y == 0)
    }

    @Test func consumeNearbyAwardsPointsAndRemovesPathogens() throws {
        let scene = MacrophagePacmanScene(size: CGSize(width: 400, height: 600), seed: 7)
        scene.spawnCurrentWave()
        let target = try #require(scene.pathogens.first)
        // Teleport the macrophage onto the first pathogen.
        scene.moveMacrophage(by: Vec2(
            x: target.position.x - scene.macrophage.position.x,
            y: target.position.y - scene.macrophage.position.y
        ))
        let consumed = scene.consumePathogensInRadius()
        #expect(consumed >= 1)
        #expect(scene.score >= target.kind.pointValue)
    }

    @Test func completedSceneIgnoresLogicCalls() {
        let scene = makeScene()
        for _ in 0..<5 { _ = scene.clearWave() }
        #expect(scene.isComplete)
        let priorScore = scene.score
        scene.recordConsume(value: 50)
        scene.spawnCurrentWave()
        scene.advancePathogens(by: 1)
        scene.moveMacrophage(by: Vec2(x: 10, y: 10))
        let consumed = scene.consumePathogensInRadius()
        #expect(scene.score == priorScore)
        #expect(consumed == 0)
    }
}
