import Foundation
import Testing
import SpriteKit
@testable import GameEngine
@testable import Models

@Suite("MicroscopeScene")
@MainActor
struct MicroscopeSceneTests {
    // Per `.claude/rules/spritekit.md` § Lazy Visual Setup: the scene's logic
    // surface is testable without GPU since `didMove(to:)` is never called.
    // We only exercise `handlePinch` / `snapToTier` which forward to the
    // `ZoomMachine`.

    private func makeScene() -> MicroscopeScene {
        MicroscopeScene(size: CGSize(width: 400, height: 600))
    }

    @Test func startsAtUnaidedTier() {
        let scene = makeScene()
        #expect(scene.machine.currentTier == .unaided)
    }

    @Test func pinchInClimbsToLight() {
        let scene = makeScene()
        scene.handlePinch(delta: 1.5)
        #expect(scene.machine.currentTier == .light)
    }

    @Test func snapToElectronWorks() {
        let scene = makeScene()
        scene.snapToTier(.electron)
        #expect(scene.machine.currentTier == .electron)
        // After snap the scene consumes the transition immediately for the
        // logic-only tests; the LOD-swap PR will retain it for the animator.
        #expect(scene.machine.pendingTransition == nil)
    }

    @Test func scaleModeIsResizeFill() {
        let scene = makeScene()
        #expect(scene.scaleMode == .resizeFill)
    }
}
