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
}
