import Foundation
import Testing
@testable import Models

@Suite("OralMicrobiomeState")
nonisolated struct OralMicrobiomeStateTests {
    @Test func emptyStateIsInOralCavitySlot() {
        let state = OralMicrobiomeState.empty
        #expect(state.underlying.activeSlot == .oralCavity)
        #expect(state.sugarLoad == .water)
        #expect(state.tickCount == 0)
        #expect(state.totalPopulation == 0)
    }

    @Test func sugarLoadCanonicalFeedingModeMapping() {
        // Per OralMicrobiomeState doc-comment + the trauma-informed posture
        // table. brushing → .none mirrors "the community settles" register;
        // sugar snack → .sugar tilts toward acid-makers; water/fruit hold
        // the balanced ecology.
        #expect(OralSugarLoad.water.feedingMode == .balanced)
        #expect(OralSugarLoad.fruit.feedingMode == .balanced)
        #expect(OralSugarLoad.sugarSnack.feedingMode == .sugar)
        #expect(OralSugarLoad.brush.feedingMode == .none)
    }

    @Test func sugarLoadRawValueStability() {
        // Load-bearing for analytics (`modeSlug: load.rawValue`) +
        // future Codable persistence. Pin every case so renames surface.
        #expect(OralSugarLoad.water.rawValue == "water")
        #expect(OralSugarLoad.fruit.rawValue == "fruit")
        #expect(OralSugarLoad.sugarSnack.rawValue == "sugarSnack")
        #expect(OralSugarLoad.brush.rawValue == "brush")
    }

    @Test func sugarLoadDisplayNameTraumaSafeRegister() {
        // Display labels surface in the Picker + accessibility value. Trauma-
        // informed: no warnings / no shaming language; "Brush" is care, not
        // an imperative.
        let labels = OralSugarLoad.allCases.map(\.displayName)
        for label in labels {
            #expect(!label.isEmpty)
            let lower = label.lowercased()
            #expect(!lower.contains("should"))
            #expect(!lower.contains("must"))
            #expect(!lower.contains("careless"))
            #expect(!lower.contains("dirty"))
        }
    }

    @Test func sugarLoadAllCasesCoversFourLoads() {
        // Future-proofs against accidental case-additions that the picker UI
        // wouldn't reflect without a corresponding View update.
        #expect(OralSugarLoad.allCases.count == 4)
        let slugs = Set(OralSugarLoad.allCases.map(\.rawValue))
        #expect(slugs == ["water", "fruit", "sugarSnack", "brush"])
    }

    @Test func sugarLoadSystemImagesAreNonEmpty() {
        // SF-Symbol mapping for the segmented picker. Empty strings would
        // silently render a blank tag — guard against future regressions.
        for load in OralSugarLoad.allCases {
            #expect(!load.systemImage.isEmpty,
                    "Sugar load \(load.rawValue) is missing an SF Symbol")
        }
    }

    @Test func codableRoundtripPreservesStateAndSugarLoad() throws {
        let original = OralMicrobiomeState(
            underlying: .empty(in: .oralCavity),
            sugarLoad: .sugarSnack
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OralMicrobiomeState.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - nextStableRun (oralBalanceKeeper criterion derivation)

    @Test func nextStableRunIncrementsUnderWater() {
        // Water is the canonical gentle load. Each tick under water extends
        // the stable run by 1 — the oral neighborhood is holding balance.
        #expect(OralMicrobiomeState.nextStableRun(prior: 0, sugarLoad: .water) == 1)
        #expect(OralMicrobiomeState.nextStableRun(prior: 7, sugarLoad: .water) == 8)
        #expect(OralMicrobiomeState.nextStableRun(prior: 42, sugarLoad: .water) == 43)
    }

    @Test func nextStableRunIncrementsUnderFruit() {
        // Fruit shares the gentle-load semantic with water.
        #expect(OralMicrobiomeState.nextStableRun(prior: 0, sugarLoad: .fruit) == 1)
        #expect(OralMicrobiomeState.nextStableRun(prior: 5, sugarLoad: .fruit) == 6)
    }

    @Test func nextStableRunResetsUnderSugarSnack() {
        // Sugar snack tilts the ecology toward acid-makers; the stable run
        // resets. Trauma-informed: the reset is ecology, NEVER framed as
        // shame in the consuming view — that framing lives in
        // `OralMicrobiomeView.refreshMentorCue`.
        #expect(OralMicrobiomeState.nextStableRun(prior: 0, sugarLoad: .sugarSnack) == 0)
        #expect(OralMicrobiomeState.nextStableRun(prior: 7, sugarLoad: .sugarSnack) == 0)
        #expect(OralMicrobiomeState.nextStableRun(prior: 42, sugarLoad: .sugarSnack) == 0)
    }

    @Test func nextStableRunHoldsUnderBrush() {
        // Brushing is care, NOT progress. Holding the run in place mirrors
        // the kid's lived experience — brushing doesn't undo a sugar snack
        // but it also doesn't earn more credit than earlier gentle loads
        // already accumulated.
        #expect(OralMicrobiomeState.nextStableRun(prior: 0, sugarLoad: .brush) == 0)
        #expect(OralMicrobiomeState.nextStableRun(prior: 7, sugarLoad: .brush) == 7)
        #expect(OralMicrobiomeState.nextStableRun(prior: 42, sugarLoad: .brush) == 42)
    }

    @Test func nextStableRunReachesThresholdUnderEightWaterTicks() {
        // Closure check: a fresh run under .water reaches the canonical
        // `OralMicrobiomeView.stableRunThreshold` of 8 in exactly 8 ticks.
        // Load-bearing — the threshold isn't part of Models, but the
        // derivation is, so this guards the canonical climb path.
        var run = 0
        for _ in 1...8 {
            run = OralMicrobiomeState.nextStableRun(prior: run, sugarLoad: .water)
        }
        #expect(run == 8)
    }

    @Test func nextStableRunBlocksThresholdWhenSugarInterrupts() {
        // Closure check: a sugar snack mid-run zeros the run; achievement
        // doesn't fire until the kid resumes gentle loads for 8 ticks.
        var run = 5
        run = OralMicrobiomeState.nextStableRun(prior: run, sugarLoad: .sugarSnack)
        #expect(run == 0)
        for _ in 1...7 {
            run = OralMicrobiomeState.nextStableRun(prior: run, sugarLoad: .fruit)
        }
        #expect(run == 7) // not yet at threshold
        run = OralMicrobiomeState.nextStableRun(prior: run, sugarLoad: .water)
        #expect(run == 8) // threshold reached
    }
}
