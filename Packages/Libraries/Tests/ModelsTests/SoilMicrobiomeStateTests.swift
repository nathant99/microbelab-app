import Foundation
import Testing
@testable import Models

@Suite("SoilMicrobiomeState")
nonisolated struct SoilMicrobiomeStateTests {
    @Test func emptyStateIsInSoilSlot() {
        let state = SoilMicrobiomeState.empty
        #expect(state.underlying.activeSlot == .soil)
        #expect(state.moistureLoad == .moist)
        #expect(state.tickCount == 0)
        #expect(state.totalPopulation == 0)
    }

    @Test func moistureLoadCanonicalFeedingModeMapping() {
        // Per SoilMicrobiomeState doc-comment + the cross-portfolio
        // pedagogy bridge. Moist → balanced (every guild thrives);
        // compost → fiber (decomposer feast); saturated → sugar
        // (anaerobic specialists thrive); drought → none (dormancy +
        // extremophile persistence).
        #expect(SoilMoistureLoad.moist.feedingMode == .balanced)
        #expect(SoilMoistureLoad.compost.feedingMode == .fiber)
        #expect(SoilMoistureLoad.saturated.feedingMode == .sugar)
        #expect(SoilMoistureLoad.drought.feedingMode == .none)
    }

    @Test func moistureLoadRawValueStability() {
        #expect(SoilMoistureLoad.moist.rawValue == "moist")
        #expect(SoilMoistureLoad.compost.rawValue == "compost")
        #expect(SoilMoistureLoad.saturated.rawValue == "saturated")
        #expect(SoilMoistureLoad.drought.rawValue == "drought")
    }

    @Test func moistureLoadDisplayNameTraumaSafeRegister() {
        // Trauma-informed register per
        // `.claude/rules/trauma-informed-content.md`: no decay-as-death
        // vocabulary, no soil-as-dirty framing, no catastrophe register
        // for drought. Cross-portfolio bridge to bioforge/ecosphere
        // demands soil-as-thriving-system framing.
        let labels = SoilMoistureLoad.allCases.map(\.displayName)
        for label in labels {
            #expect(!label.isEmpty)
            let lower = label.lowercased()
            #expect(!lower.contains("dirty"))
            #expect(!lower.contains("gross"))
            #expect(!lower.contains("nasty"))
            #expect(!lower.contains("rot"))
            #expect(!lower.contains("dead"))
            #expect(!lower.contains("doom"))
        }
    }

    @Test func moistureLoadAllCasesCoversFourLoads() {
        #expect(SoilMoistureLoad.allCases.count == 4)
        let slugs = Set(SoilMoistureLoad.allCases.map(\.rawValue))
        #expect(slugs == ["moist", "compost", "saturated", "drought"])
    }

    @Test func moistureLoadSystemImagesAreNonEmpty() {
        for load in SoilMoistureLoad.allCases {
            #expect(!load.systemImage.isEmpty,
                    "Moisture load \(load.rawValue) is missing an SF Symbol")
        }
    }

    @Test func codableRoundtripPreservesStateAndMoistureLoad() throws {
        let original = SoilMicrobiomeState(
            underlying: .empty(in: .soil),
            moistureLoad: .compost
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SoilMicrobiomeState.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - nextStableRun (soilDecomposerWhisperer criterion derivation)

    @Test func nextStableRunIncrementsUnderMoist() {
        #expect(SoilMicrobiomeState.nextStableRun(prior: 0, moistureLoad: .moist) == 1)
        #expect(SoilMicrobiomeState.nextStableRun(prior: 7, moistureLoad: .moist) == 8)
    }

    @Test func nextStableRunIncrementsUnderCompost() {
        // Compost pulse is the decomposers' favorite feast — extends
        // the stable run.
        #expect(SoilMicrobiomeState.nextStableRun(prior: 0, moistureLoad: .compost) == 1)
        #expect(SoilMicrobiomeState.nextStableRun(prior: 5, moistureLoad: .compost) == 6)
    }

    @Test func nextStableRunResetsUnderSaturated() {
        // Saturated soil displaces air pockets; aerobic guild dwindles.
        // The stable run resets — but the framing is ecology, NEVER
        // failure (the mentor copy in SoilMicrobiomeView surfaces "only
        // the anaerobic specialists thrive — that's ecology, not
        // failure").
        #expect(SoilMicrobiomeState.nextStableRun(prior: 0, moistureLoad: .saturated) == 0)
        #expect(SoilMicrobiomeState.nextStableRun(prior: 7, moistureLoad: .saturated) == 0)
        #expect(SoilMicrobiomeState.nextStableRun(prior: 42, moistureLoad: .saturated) == 0)
    }

    @Test func nextStableRunHoldsUnderDrought() {
        // Drought slows everything down. Extremophiles persist; the rest
        // go dormant. Holding the run in place mirrors the kid's lived
        // experience — a drought doesn't undo earlier balance, it just
        // pauses growth.
        #expect(SoilMicrobiomeState.nextStableRun(prior: 0, moistureLoad: .drought) == 0)
        #expect(SoilMicrobiomeState.nextStableRun(prior: 7, moistureLoad: .drought) == 7)
        #expect(SoilMicrobiomeState.nextStableRun(prior: 42, moistureLoad: .drought) == 42)
    }

    @Test func nextStableRunReachesThresholdUnderEightMoistTicks() {
        var run = 0
        for _ in 1...8 {
            run = SoilMicrobiomeState.nextStableRun(prior: run, moistureLoad: .moist)
        }
        #expect(run == 8)
    }

    @Test func nextStableRunBlocksThresholdWhenSaturatedInterrupts() {
        var run = 5
        run = SoilMicrobiomeState.nextStableRun(prior: run, moistureLoad: .saturated)
        #expect(run == 0)
        for _ in 1...7 {
            run = SoilMicrobiomeState.nextStableRun(prior: run, moistureLoad: .compost)
        }
        #expect(run == 7)
        run = SoilMicrobiomeState.nextStableRun(prior: run, moistureLoad: .moist)
        #expect(run == 8)
    }

    @Test func nextStableRunPreservesProgressAcrossDroughtPeriod() {
        // Pedagogy invariant: a kid who built up 5 thriving ticks then
        // hits a drought period doesn't lose progress — the run pauses
        // and resumes when moisture returns. Demonstrates the kid's
        // care isn't undone by external conditions.
        var run = 0
        for _ in 1...5 {
            run = SoilMicrobiomeState.nextStableRun(prior: run, moistureLoad: .moist)
        }
        #expect(run == 5)
        for _ in 1...10 {
            run = SoilMicrobiomeState.nextStableRun(prior: run, moistureLoad: .drought)
        }
        #expect(run == 5)
        for _ in 1...3 {
            run = SoilMicrobiomeState.nextStableRun(prior: run, moistureLoad: .compost)
        }
        #expect(run == 8)
    }
}
