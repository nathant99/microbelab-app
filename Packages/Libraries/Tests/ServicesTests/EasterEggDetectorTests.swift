import Foundation
import Testing
@testable import Services
@testable import Models

@Suite("EasterEggDetector")
struct EasterEggDetectorTests {
    @Test func freshDetectorHasNothing() {
        let detector = EasterEggDetector()
        #expect(detector.visitedTiers.isEmpty)
        #expect(detector.didJustReachAllTiers == false)
        #expect(detector.hasAcknowledgedAllTiers == false)
    }

    @Test func recordingThreeTiersDoesNotTrigger() {
        var detector = EasterEggDetector()
        #expect(detector.record(visit: .unaided) == false)
        #expect(detector.record(visit: .light) == false)
        #expect(detector.record(visit: .fluorescence) == false)
        #expect(detector.didJustReachAllTiers == false)
    }

    @Test func recordingAllFourTiersTriggersOnTheFourth() {
        var detector = EasterEggDetector()
        _ = detector.record(visit: .unaided)
        _ = detector.record(visit: .light)
        _ = detector.record(visit: .fluorescence)
        let didTrigger = detector.record(visit: .electron)
        #expect(didTrigger == true)
        #expect(detector.didJustReachAllTiers == true)
        #expect(detector.visitedTiers.count == 4)
    }

    @Test func reVisitingAlreadySeenTierDoesNotRetrigger() {
        var detector = EasterEggDetector()
        // Reach all 4 + acknowledge.
        _ = detector.record(visit: .unaided)
        _ = detector.record(visit: .light)
        _ = detector.record(visit: .fluorescence)
        _ = detector.record(visit: .electron)
        detector.acknowledgeAllTiersReached()
        #expect(detector.hasAcknowledgedAllTiers == true)
        #expect(detector.didJustReachAllTiers == false)
        // Re-visit any tier — must not re-trigger.
        let retrigger = detector.record(visit: .unaided)
        #expect(retrigger == false)
        #expect(detector.didJustReachAllTiers == false)
    }

    @Test func acknowledgingClearsTheOneShotFlag() {
        var detector = EasterEggDetector()
        _ = detector.record(visit: .unaided)
        _ = detector.record(visit: .light)
        _ = detector.record(visit: .fluorescence)
        _ = detector.record(visit: .electron)
        #expect(detector.didJustReachAllTiers == true)
        detector.acknowledgeAllTiersReached()
        #expect(detector.didJustReachAllTiers == false)
    }

    @Test func tiersVisitedInAnyOrderCounts() {
        // Backwards order — same result.
        var detector = EasterEggDetector()
        _ = detector.record(visit: .electron)
        _ = detector.record(visit: .fluorescence)
        _ = detector.record(visit: .light)
        let triggered = detector.record(visit: .unaided)
        #expect(triggered == true)
    }

    @Test func resetRestoresInitialState() {
        var detector = EasterEggDetector()
        _ = detector.record(visit: .unaided)
        _ = detector.record(visit: .light)
        detector.reset()
        #expect(detector.visitedTiers.isEmpty)
        #expect(detector.didJustReachAllTiers == false)
        #expect(detector.hasAcknowledgedAllTiers == false)
    }

    // MARK: - Curious-explorer microbe selection

    @Test func curiousExplorerMicrobeIsDeterministicPerSession() {
        let slugs = ["lacto", "yeast", "photo", "net", "spore", "guard"]
        let a = EasterEggDetector.curiousExplorerMicrobe(forSessionCount: 7, microbeSlugs: slugs)
        let b = EasterEggDetector.curiousExplorerMicrobe(forSessionCount: 7, microbeSlugs: slugs)
        #expect(a != nil)
        #expect(a == b)
    }

    @Test func curiousExplorerMicrobeReturnsNilOnEmptyCatalog() {
        #expect(EasterEggDetector.curiousExplorerMicrobe(
            forSessionCount: 1,
            microbeSlugs: []
        ) == nil)
    }

    @Test func curiousExplorerMicrobeAlwaysPicksFromTheCatalog() {
        let slugs = ["lacto", "yeast", "photo"]
        for session in 1...50 {
            let pick = EasterEggDetector.curiousExplorerMicrobe(
                forSessionCount: session,
                microbeSlugs: slugs
            )
            #expect(pick.map(slugs.contains) ?? false,
                    "session \(session) picked \(pick ?? "nil") outside the catalog")
        }
    }

    @Test func curiousExplorerSaltDecorrelatesFromVariableReward() {
        // The two salts are intentionally distinct so the easter-egg
        // selection on a given session never lines up with the same
        // session's variable-reward selection. The selectors are
        // independent surfaces; correlating them would feel scripted.
        // Empirical spot-check: at least one session of the first 20
        // should pick a different microbe than the variable-reward
        // surface (when both pick microbes — variable-reward only fires
        // ~1 in 5 sessions).
        let slugs = ["a", "b", "c", "d", "e", "f", "g"]
        var disagreements = 0
        for session in 1...20 {
            let egg = EasterEggDetector.curiousExplorerMicrobe(
                forSessionCount: session,
                microbeSlugs: slugs
            )
            if case .rareMicrobeSighting(let varSlug) = VariableRewardSelector.select(
                forSessionCount: session,
                microbeSlugs: slugs
            ) {
                if egg != varSlug { disagreements += 1 }
            }
        }
        // At least one disagreement in 20 sessions means the salts aren't
        // identical. (Stronger guarantees come from the test that
        // verifies both selectors are deterministic given the same input —
        // this just sanity-checks that they don't collide on every draw.)
        #expect(disagreements >= 1)
    }
}
