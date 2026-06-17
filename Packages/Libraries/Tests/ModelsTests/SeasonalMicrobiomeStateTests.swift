import Foundation
import Testing
@testable import Models

@Suite("SeasonalMicrobiomeState")
nonisolated struct SeasonalMicrobiomeStateTests {
    @Test func emptyStateIsInLargeIntestineSlotUnderWinterCold() {
        let state = SeasonalMicrobiomeState.empty
        #expect(state.underlying.activeSlot == .largeIntestine)
        #expect(state.load == .winterCold)
        #expect(state.tickCount == 0)
        #expect(state.totalPopulation == 0)
    }

    @Test func seasonalLoadCanonicalFeedingModeMapping() {
        // Per SeasonalMicrobiomeState doc-comment + the trauma-informed
        // posture table. cold → balanced (immune library busy on a respira-
        // tory bug; gut holding its mix); allergy → sugar (pollen distur-
        // bance modeled as a growth spike, NEVER as "fighting"); summer →
        // fiber (produce season favors fiber-loving microbes); autumn →
        // none (body settling).
        #expect(SeasonalLoad.winterCold.feedingMode == .balanced)
        #expect(SeasonalLoad.springAllergy.feedingMode == .sugar)
        #expect(SeasonalLoad.summerWarm.feedingMode == .fiber)
        #expect(SeasonalLoad.autumnSettle.feedingMode == .none)
    }

    @Test func seasonalLoadRawValueStability() {
        // Load-bearing for analytics (`modeSlug: load.rawValue`) +
        // future Codable persistence. Pin every case so renames surface.
        #expect(SeasonalLoad.winterCold.rawValue == "winterCold")
        #expect(SeasonalLoad.springAllergy.rawValue == "springAllergy")
        #expect(SeasonalLoad.summerWarm.rawValue == "summerWarm")
        #expect(SeasonalLoad.autumnSettle.rawValue == "autumnSettle")
    }

    @Test func seasonalLoadDisplayNameTraumaSafeRegister() {
        // Display labels surface in the Picker + accessibility value. The
        // load-bearing trauma-informed posture for seasonal content is that
        // cold is "the immune library is busy" NOT "sick"; allergy is "the
        // body noticing pollen" NOT "attacked"; pollen is sensory NOT enemy.
        // The labels themselves stay short + body-affirming; full per-load
        // mentor copy will land with the scene + reviewer signoff.
        let stoplist = [
            // Disease + body framing
            "sick", "sickness", "ill", "illness", "disease", "infected",
            // Warfare
            "fight", "attack", "battle", "war", "enemy", "weapon",
            // Shame
            "should", "must", "lazy", "careless",
            // Threat
            "scary", "dangerous", "doom",
        ]
        let labels = SeasonalLoad.allCases.map(\.displayName)
        for label in labels {
            #expect(!label.isEmpty)
            let lower = label.lowercased()
            for forbidden in stoplist {
                #expect(!lower.contains(forbidden),
                        "Seasonal load label '\(label)' contains forbidden token '\(forbidden)'")
            }
        }
    }

    @Test func seasonalLoadAllCasesCoversFourLoads() {
        // Future-proofs against accidental case-additions that the picker UI
        // wouldn't reflect without a corresponding View update.
        #expect(SeasonalLoad.allCases.count == 4)
        let slugs = Set(SeasonalLoad.allCases.map(\.rawValue))
        #expect(slugs == ["winterCold", "springAllergy", "summerWarm", "autumnSettle"])
    }

    @Test func seasonalLoadSystemImagesAreNonEmpty() {
        // SF-Symbol mapping for the segmented picker. Empty strings would
        // silently render a blank tag — guard against future regressions.
        for load in SeasonalLoad.allCases {
            #expect(!load.systemImage.isEmpty,
                    "Seasonal load \(load.rawValue) is missing an SF Symbol")
        }
    }

    @Test func codableRoundtripPreservesStateAndLoad() throws {
        let original = SeasonalMicrobiomeState(
            underlying: .empty(in: .largeIntestine),
            load: .springAllergy
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SeasonalMicrobiomeState.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - nextStableRun (seasonalAwareness criterion derivation)

    @Test func nextStableRunIncrementsUnderWinterCold() {
        // Winter holds the body's normal mix — the immune library is working
        // without disturbing the gut community. Stable run extends.
        #expect(SeasonalMicrobiomeState.nextStableRun(prior: 0, load: .winterCold) == 1)
        #expect(SeasonalMicrobiomeState.nextStableRun(prior: 7, load: .winterCold) == 8)
        #expect(SeasonalMicrobiomeState.nextStableRun(prior: 42, load: .winterCold) == 43)
    }

    @Test func nextStableRunIncrementsUnderSummerWarm() {
        // Summer favors fiber-loving microbes on produce season — stable run
        // extends the same way winter does.
        #expect(SeasonalMicrobiomeState.nextStableRun(prior: 0, load: .summerWarm) == 1)
        #expect(SeasonalMicrobiomeState.nextStableRun(prior: 5, load: .summerWarm) == 6)
    }

    @Test func nextStableRunResetsUnderSpringAllergy() {
        // Spring allergy surfaces an IgE response that shifts the gut
        // ecology. Resetting is ecology, NEVER framed as shame in any
        // consuming surface — the per-load mentor cue (when authored)
        // frames allergy as sensory noticing.
        #expect(SeasonalMicrobiomeState.nextStableRun(prior: 0, load: .springAllergy) == 0)
        #expect(SeasonalMicrobiomeState.nextStableRun(prior: 7, load: .springAllergy) == 0)
        #expect(SeasonalMicrobiomeState.nextStableRun(prior: 42, load: .springAllergy) == 0)
    }

    @Test func nextStableRunHoldsUnderAutumnSettle() {
        // Autumn settling holds the run in place — the body is transitioning
        // + recovering from summer. Holding mirrors "settling" rather than
        // "progressing" or "regressing".
        #expect(SeasonalMicrobiomeState.nextStableRun(prior: 0, load: .autumnSettle) == 0)
        #expect(SeasonalMicrobiomeState.nextStableRun(prior: 7, load: .autumnSettle) == 7)
        #expect(SeasonalMicrobiomeState.nextStableRun(prior: 42, load: .autumnSettle) == 42)
    }

    @Test func nextStableRunReachesThresholdUnderEightWinterTicks() {
        // Closure check: a fresh run under winter cold reaches a canonical
        // threshold of 8 in exactly 8 ticks. Mirrors OralMicrobiomeState's
        // 8-tick canonical run (the future SeasonalMicrobiomeView consumer
        // will use the same threshold for the seasonalAwareness achievement
        // predicate).
        var run = 0
        for _ in 1...8 {
            run = SeasonalMicrobiomeState.nextStableRun(prior: run, load: .winterCold)
        }
        #expect(run == 8)
    }

    @Test func nextStableRunBlocksThresholdWhenAllergyInterrupts() {
        // Closure check: a spring-allergy tick mid-run zeros the run;
        // achievement doesn't fire until the kid resumes gentle loads.
        // Same pedagogy invariant as the oral-microbiome sugar-snack
        // interrupt test.
        var run = 5
        run = SeasonalMicrobiomeState.nextStableRun(prior: run, load: .springAllergy)
        #expect(run == 0)
        for _ in 1...7 {
            run = SeasonalMicrobiomeState.nextStableRun(prior: run, load: .summerWarm)
        }
        #expect(run == 7) // not yet at threshold
        run = SeasonalMicrobiomeState.nextStableRun(prior: run, load: .winterCold)
        #expect(run == 8) // threshold reached
    }

    @Test func autumnSettleAfterSummerHoldsAccumulatedRun() {
        // The autumn-after-summer transition. Summer accumulates the run;
        // autumn holds it. Mirrors the lived experience of "the body
        // recovering" — accumulated wellness doesn't regress just because
        // the season shifts.
        var run = 0
        for _ in 1...5 {
            run = SeasonalMicrobiomeState.nextStableRun(prior: run, load: .summerWarm)
        }
        #expect(run == 5)
        for _ in 1...3 {
            run = SeasonalMicrobiomeState.nextStableRun(prior: run, load: .autumnSettle)
        }
        #expect(run == 5) // accumulated run held across autumn
    }
}
