import Foundation
import Testing
@testable import Services

@Suite("AdaptiveImmunityProgressStore")
@MainActor
struct AdaptiveImmunityProgressStoreTests {
    private static func makeIsolatedDefaults(_ suite: String = #function) -> UserDefaults {
        let name = "AdaptiveImmunityProgressStoreTests-\(suite)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func freshStoreIsEmpty() {
        let store = AdaptiveImmunityProgressStore(defaults: Self.makeIsolatedDefaults())
        #expect(store.innateRunsCompleted == 0)
        #expect(store.perfectInnateRuns == 0)
        #expect(!store.unlock().isUnlocked)
    }

    @Test func recordRunIncrementsRunCount() {
        let store = AdaptiveImmunityProgressStore(defaults: Self.makeIsolatedDefaults())
        store.recordRunCompleted(perfectRun: false)
        #expect(store.innateRunsCompleted == 1)
        #expect(store.perfectInnateRuns == 0)
    }

    @Test func recordPerfectRunIncrementsBothCounters() {
        let store = AdaptiveImmunityProgressStore(defaults: Self.makeIsolatedDefaults())
        store.recordRunCompleted(perfectRun: true)
        #expect(store.innateRunsCompleted == 1)
        #expect(store.perfectInnateRuns == 1)
    }

    @Test func standardPathUnlocksAfterThreeRuns() {
        let store = AdaptiveImmunityProgressStore(defaults: Self.makeIsolatedDefaults())
        store.recordRunCompleted(perfectRun: false)
        store.recordRunCompleted(perfectRun: false)
        #expect(!store.unlock().isUnlocked)
        store.recordRunCompleted(perfectRun: false)
        #expect(store.unlock().isUnlocked)
    }

    @Test func perfectRunUnlocksImmediately() {
        let store = AdaptiveImmunityProgressStore(defaults: Self.makeIsolatedDefaults())
        store.recordRunCompleted(perfectRun: true)
        #expect(store.unlock().isUnlocked)
    }

    @Test func simplifyChallengeBypassesPersistedState() {
        let store = AdaptiveImmunityProgressStore(defaults: Self.makeIsolatedDefaults())
        // Zero runs, zero perfect — but the parent toggle bypasses the gate.
        #expect(store.unlock(simplifyChallenge: true).isUnlocked)
    }

    @Test func countsPersistAcrossInstances() {
        let defaults = Self.makeIsolatedDefaults()
        let first = AdaptiveImmunityProgressStore(defaults: defaults)
        first.recordRunCompleted(perfectRun: false)
        first.recordRunCompleted(perfectRun: true)

        let second = AdaptiveImmunityProgressStore(defaults: defaults)
        #expect(second.innateRunsCompleted == 2)
        #expect(second.perfectInnateRuns == 1)
        // 1 perfect run is enough to be unlocked via the fast-track.
        #expect(second.unlock().isUnlocked)
    }

    @Test func clearForTestingResetsState() {
        let store = AdaptiveImmunityProgressStore(defaults: Self.makeIsolatedDefaults())
        store.recordRunCompleted(perfectRun: true)
        store.recordRunCompleted(perfectRun: true)
        store.clearForTesting()
        #expect(store.innateRunsCompleted == 0)
        #expect(store.perfectInnateRuns == 0)
        #expect(!store.unlock().isUnlocked)
    }

    @Test func keysAreStable() {
        // Load-bearing for the JSON-less UserDefaults schema. If these
        // change, existing kids' progress disappears silently.
        #expect(AdaptiveImmunityProgressStore.runsKey == "com.microbelab.adaptive.innateRunsCompleted")
        #expect(AdaptiveImmunityProgressStore.perfectRunsKey == "com.microbelab.adaptive.perfectInnateRuns")
    }
}
