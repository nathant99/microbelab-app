import Foundation
import Testing
@testable import Models

@Suite("SkinMicrobiomeState")
nonisolated struct SkinMicrobiomeStateTests {
    @Test func emptyStateIsInSkinSlot() {
        let state = SkinMicrobiomeState.empty
        #expect(state.underlying.activeSlot == .skin)
        #expect(state.careLoad == .gentleWash)
        #expect(state.tickCount == 0)
        #expect(state.totalPopulation == 0)
    }

    @Test func careLoadCanonicalFeedingModeMapping() {
        // Per SkinMicrobiomeState doc-comment + the trauma-informed posture
        // table. Gentle care (gentleWash/barrier) → .balanced; scratching
        // disturbance → .sugar (uneven flora toward disturbance-tolerant
        // neighbors); rest → .none (community settles when left alone).
        #expect(SkinCareLoad.gentleWash.feedingMode == .balanced)
        #expect(SkinCareLoad.barrier.feedingMode == .balanced)
        #expect(SkinCareLoad.scratch.feedingMode == .sugar)
        #expect(SkinCareLoad.restRecover.feedingMode == .none)
    }

    @Test func careLoadRawValueStability() {
        // Load-bearing for analytics (modeSlug:) + future Codable
        // persistence. Pin every case so renames surface.
        #expect(SkinCareLoad.gentleWash.rawValue == "gentleWash")
        #expect(SkinCareLoad.barrier.rawValue == "barrier")
        #expect(SkinCareLoad.scratch.rawValue == "scratch")
        #expect(SkinCareLoad.restRecover.rawValue == "restRecover")
    }

    @Test func careLoadDisplayNameTraumaSafeRegister() {
        // Eczema-safe trauma-informed posture per
        // `.claude/rules/trauma-informed-content.md`: no clinical-judgment
        // vocabulary, no body-shame framing, no imperative "should/must"
        // anywhere on the surface. The "Itchy day" name acknowledges the
        // kid's lived experience without framing scratching as failure.
        let labels = SkinCareLoad.allCases.map(\.displayName)
        for label in labels {
            #expect(!label.isEmpty)
            let lower = label.lowercased()
            #expect(!lower.contains("should"))
            #expect(!lower.contains("must"))
            #expect(!lower.contains("dirty"))
            #expect(!lower.contains("gross"))
            #expect(!lower.contains("ashamed"))
            #expect(!lower.contains("ugly"))
            #expect(!lower.contains("acne"))
        }
    }

    @Test func careLoadAllCasesCoversFourLoads() {
        #expect(SkinCareLoad.allCases.count == 4)
        let slugs = Set(SkinCareLoad.allCases.map(\.rawValue))
        #expect(slugs == ["gentleWash", "barrier", "scratch", "restRecover"])
    }

    @Test func careLoadSystemImagesAreNonEmpty() {
        for load in SkinCareLoad.allCases {
            #expect(!load.systemImage.isEmpty,
                    "Care load \(load.rawValue) is missing an SF Symbol")
        }
    }

    @Test func codableRoundtripPreservesStateAndCareLoad() throws {
        let original = SkinMicrobiomeState(
            underlying: .empty(in: .skin),
            careLoad: .barrier
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SkinMicrobiomeState.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - nextStableRun (skinKindnessChampion criterion derivation)

    @Test func nextStableRunIncrementsUnderGentleWash() {
        #expect(SkinMicrobiomeState.nextStableRun(prior: 0, careLoad: .gentleWash) == 1)
        #expect(SkinMicrobiomeState.nextStableRun(prior: 7, careLoad: .gentleWash) == 8)
    }

    @Test func nextStableRunIncrementsUnderBarrier() {
        #expect(SkinMicrobiomeState.nextStableRun(prior: 0, careLoad: .barrier) == 1)
        #expect(SkinMicrobiomeState.nextStableRun(prior: 5, careLoad: .barrier) == 6)
    }

    @Test func nextStableRunResetsUnderScratch() {
        // Itchy day jumbles the flora; the stable run resets. Trauma-
        // informed: ecology, NEVER blame — the framing of "the kid scratched
        // = the run reset" lives in `SkinMicrobiomeView.refreshMentorCue`.
        #expect(SkinMicrobiomeState.nextStableRun(prior: 0, careLoad: .scratch) == 0)
        #expect(SkinMicrobiomeState.nextStableRun(prior: 7, careLoad: .scratch) == 0)
        #expect(SkinMicrobiomeState.nextStableRun(prior: 42, careLoad: .scratch) == 0)
    }

    @Test func nextStableRunHoldsUnderRestRecover() {
        // Rest is care, NOT progress. Holding the run in place mirrors
        // the kid's lived experience — taking a break doesn't earn more
        // credit, just preserves what was already accumulated.
        #expect(SkinMicrobiomeState.nextStableRun(prior: 0, careLoad: .restRecover) == 0)
        #expect(SkinMicrobiomeState.nextStableRun(prior: 7, careLoad: .restRecover) == 7)
        #expect(SkinMicrobiomeState.nextStableRun(prior: 42, careLoad: .restRecover) == 42)
    }

    @Test func nextStableRunReachesThresholdUnderEightGentleWashTicks() {
        var run = 0
        for _ in 1...8 {
            run = SkinMicrobiomeState.nextStableRun(prior: run, careLoad: .gentleWash)
        }
        #expect(run == 8)
    }

    @Test func nextStableRunBlocksThresholdWhenScratchInterrupts() {
        // Itchy day mid-run zeros the run; achievement doesn't fire
        // until gentle care resumes for 8 more ticks. Pedagogy: the kid
        // sees that disturbance pushes the garden out of balance, but
        // care brings it back — no failure framing.
        var run = 5
        run = SkinMicrobiomeState.nextStableRun(prior: run, careLoad: .scratch)
        #expect(run == 0)
        for _ in 1...7 {
            run = SkinMicrobiomeState.nextStableRun(prior: run, careLoad: .barrier)
        }
        #expect(run == 7)
        run = SkinMicrobiomeState.nextStableRun(prior: run, careLoad: .gentleWash)
        #expect(run == 8)
    }
}
