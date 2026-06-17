import Foundation
import Testing
import CoreGraphics
@testable import GameEngine
@testable import Models

@Suite("DiseaseStoryNarrativeScene")
@MainActor
final class DiseaseStoryNarrativeSceneTests {
    nonisolated deinit {}

    private func makeScene(arc: DiseaseStoryArc = .handwashing) -> DiseaseStoryNarrativeScene {
        DiseaseStoryNarrativeScene(
            size: CGSize(width: 400, height: 400),
            arc: arc
        )
    }

    @Test func initializesAtIntroductionBeat() {
        let scene = makeScene()
        #expect(scene.currentBeatIndex == 0)
        #expect(scene.currentBeat == .introduction)
        #expect(scene.totalBeats == 4)
    }

    @Test func initializesWithRequestedArc() {
        let scene = makeScene(arc: .vaccinePriming)
        #expect(scene.arc == .vaccinePriming)
    }

    @Test func advanceBeatSteppingThroughEveryBeat() {
        let scene = makeScene()
        // Step through every beat. The currentBeat enum must follow the
        // canonical index sequence.
        scene.advanceBeat()
        #expect(scene.currentBeatIndex == 1)
        #expect(scene.currentBeat == .witness)

        scene.advanceBeat()
        #expect(scene.currentBeatIndex == 2)
        #expect(scene.currentBeat == .action)

        scene.advanceBeat()
        #expect(scene.currentBeatIndex == 3)
        #expect(scene.currentBeat == .reflection)
    }

    @Test func advanceBeatClampsAtLastBeat() {
        let scene = makeScene()
        // Advance to last beat then overflow — must clamp, NOT wrap.
        for _ in 0..<10 { scene.advanceBeat() }
        #expect(scene.currentBeatIndex == 3)
        #expect(scene.currentBeat == .reflection)
    }

    @Test func retreatBeatClampsAtZero() {
        let scene = makeScene()
        // Retreat at index 0 — must clamp, NOT go negative.
        scene.retreatBeat()
        #expect(scene.currentBeatIndex == 0)
        #expect(scene.currentBeat == .introduction)

        // Advance + retreat round-trip.
        scene.advanceBeat()
        scene.advanceBeat()
        #expect(scene.currentBeatIndex == 2)
        scene.retreatBeat()
        #expect(scene.currentBeatIndex == 1)
        scene.retreatBeat()
        #expect(scene.currentBeatIndex == 0)
        scene.retreatBeat()
        #expect(scene.currentBeatIndex == 0) // clamped
    }

    @Test func resetToFirstBeatReturnsToIntroduction() {
        let scene = makeScene()
        scene.advanceBeat()
        scene.advanceBeat()
        #expect(scene.currentBeatIndex == 2)
        scene.resetToFirstBeat()
        #expect(scene.currentBeatIndex == 0)
        #expect(scene.currentBeat == .introduction)
    }

    @Test func setArcResetsBeatIndex() {
        let scene = makeScene()
        scene.advanceBeat()
        scene.advanceBeat()
        #expect(scene.currentBeatIndex == 2)
        scene.setArc(.outbreakRecovery)
        #expect(scene.arc == .outbreakRecovery)
        #expect(scene.currentBeatIndex == 0)
    }

    @Test func configureVisualsIsIdempotent() {
        // Per `.claude/rules/spritekit.md` § Lazy Visual Setup — the second
        // call must early-return so a future re-attach to a view (didMove
        // twice) doesn't duplicate child nodes.
        let scene = makeScene()
        scene.configureVisuals()
        let firstChildCount = scene.children.count
        scene.configureVisuals()
        let secondChildCount = scene.children.count
        #expect(firstChildCount == secondChildCount)
    }

    @Test func sceneRetainsCanonicalContentNodes() {
        // The scaffold ships three layer anchors per the seasonal /
        // oral / skin / soil scene pattern: contentRoot (parent) +
        // beatLayer (where per-beat illustrations will land) +
        // hudAnchorLayer (where overlay sprites will land). Pin them so
        // a future refactor doesn't silently drop a layer.
        let scene = makeScene()
        scene.configureVisuals()
        #expect(scene.contentRoot.parent === scene)
        #expect(scene.beatLayer.parent === scene.contentRoot)
        #expect(scene.hudAnchorLayer.parent === scene.contentRoot)
    }
}
