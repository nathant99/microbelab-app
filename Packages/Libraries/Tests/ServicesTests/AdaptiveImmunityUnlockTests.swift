import Foundation
import Testing
@testable import Services

@Suite("AdaptiveImmunityUnlock")
struct AdaptiveImmunityUnlockTests {
    @Test func freshKidIsLocked() {
        let unlock = AdaptiveImmunityUnlock.from(
            innateRunsCompleted: 0,
            perfectInnateRuns: 0
        )
        guard case let .locked(progress, runsRemaining) = unlock else {
            Issue.record("Expected fresh kid to be locked, got \(unlock)")
            return
        }
        #expect(progress == 0.0)
        #expect(runsRemaining == 3)
        #expect(!unlock.isUnlocked)
    }

    @Test func partialProgressStaysLocked() {
        let unlock = AdaptiveImmunityUnlock.from(
            innateRunsCompleted: 2,
            perfectInnateRuns: 0
        )
        guard case let .locked(progress, runsRemaining) = unlock else {
            Issue.record("Expected partial progress to be locked, got \(unlock)")
            return
        }
        #expect(progress > 0.6 && progress < 0.7)
        #expect(runsRemaining == 1)
    }

    @Test func threeRunsUnlocksStandardPath() {
        let unlock = AdaptiveImmunityUnlock.from(
            innateRunsCompleted: 3,
            perfectInnateRuns: 0
        )
        #expect(unlock == .unlocked)
        #expect(unlock.isUnlocked)
    }

    @Test func extraRunsBeyondThresholdStayUnlocked() {
        let unlock = AdaptiveImmunityUnlock.from(
            innateRunsCompleted: 10,
            perfectInnateRuns: 0
        )
        #expect(unlock == .unlocked)
    }

    @Test func singlePerfectRunFastTracksUnlock() {
        // A kid who nails the innate surface on the first try gets immediate
        // access to the adaptive scene — pedagogy reward.
        let unlock = AdaptiveImmunityUnlock.from(
            innateRunsCompleted: 1,
            perfectInnateRuns: 1
        )
        #expect(unlock == .unlocked)
    }

    @Test func simplifyChallengeBypassesGate() {
        // Parent-gated chill mode: the kid never has to earn their way in.
        let unlock = AdaptiveImmunityUnlock.from(
            innateRunsCompleted: 0,
            perfectInnateRuns: 0,
            simplifyChallenge: true
        )
        #expect(unlock == .unlocked)
    }

    @Test func negativeCountsTreatedAsZero() {
        // Defensive: persisted state could in theory underflow; never crash.
        let unlock = AdaptiveImmunityUnlock.from(
            innateRunsCompleted: -1,
            perfectInnateRuns: -3
        )
        guard case let .locked(progress, runsRemaining) = unlock else {
            Issue.record("Negative input should be treated as zero (locked)")
            return
        }
        #expect(progress == 0.0)
        #expect(runsRemaining == 3)
    }

    @Test func unlockedHasNoExplainerCopy() {
        #expect(AdaptiveImmunityUnlock.unlocked.unlockExplainerCopy == nil)
    }

    @Test func lockedExplainerSurfacesRemainingCount() {
        let unlock = AdaptiveImmunityUnlock.from(
            innateRunsCompleted: 1,
            perfectInnateRuns: 0
        )
        let copy = unlock.unlockExplainerCopy
        #expect(copy != nil)
        #expect(copy?.contains("2") == true)
        #expect(copy?.contains("B-cell") == true)
    }

    @Test func lockedExplainerHandlesSingularRun() {
        let unlock = AdaptiveImmunityUnlock.from(
            innateRunsCompleted: 2,
            perfectInnateRuns: 0
        )
        let copy = unlock.unlockExplainerCopy
        #expect(copy == "One more innate run to meet the B-cell library.")
    }

    /// Trauma-informed copy stoplist — the unlock explainer must never
    /// frame remaining work as failure, behindness, or shame.
    /// Mirrors `MasteryMomentDetector` + `CodexCertificate` stoplist
    /// patterns. The "should" exclusion is the canonical anti-shame guard.
    @Test(arguments: [
        "failed", "behind", "should", "must", "almost",
        "fell short", "compared", "better than", "lost",
        "not yet ready", "haven't", "didn't"
    ])
    func explainerCopyAvoidsShameVocabulary(token: String) {
        for runsCompleted in 0...2 {
            let unlock = AdaptiveImmunityUnlock.from(
                innateRunsCompleted: runsCompleted,
                perfectInnateRuns: 0
            )
            if let copy = unlock.unlockExplainerCopy {
                let lowered = copy.lowercased()
                #expect(
                    !lowered.contains(token),
                    "Unlock copy '\(copy)' for runs=\(runsCompleted) must not contain '\(token)'"
                )
            }
        }
    }
}
