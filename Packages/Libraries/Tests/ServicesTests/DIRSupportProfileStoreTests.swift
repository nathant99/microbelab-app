import Foundation
import Testing
import ForgeDevelopmental
@testable import Services

@Suite("DIRSupportProfileStore")
@MainActor
struct DIRSupportProfileStoreTests {
    /// Per `.claude/rules/testing.md` § Crash-Resilience Defaults — every
    /// UserDefaults-using test isolates to a per-file suite + wipes it on
    /// init so cross-test pollution can't leak.
    private static func makeIsolatedDefaults(_ suite: String = #function) -> UserDefaults {
        let defaults = UserDefaults(suiteName: "DIRSupportProfileStoreTests-\(suite)") ?? .standard
        defaults.removePersistentDomain(forName: "DIRSupportProfileStoreTests-\(suite)")
        return defaults
    }

    @Test func freshStoreHasEmptyProfile() {
        let store = DIRSupportProfileStore(defaults: Self.makeIsolatedDefaults())
        #expect(store.profile.demonstrations.isEmpty)
        #expect(store.currentLevel == nil)
        #expect(store.estimatedBand == nil)
        #expect(!store.hasAnyDemonstration)
    }

    @Test func recordDemonstrationAppendsRecord() {
        let store = DIRSupportProfileStore(defaults: Self.makeIsolatedDefaults())
        store.recordDemonstration(
            level: .reflectiveThinking,
            context: .reflection,
            confidence: .clear
        )
        #expect(store.profile.demonstrations.count == 1)
        #expect(store.profile.demonstrations.first?.fedcLevel == .reflectiveThinking)
        #expect(store.profile.demonstrations.first?.context == .reflection)
        #expect(store.profile.demonstrations.first?.confidence == .clear)
        #expect(store.profile.demonstrations.first?.appIdentifier == DIRSupportProfileStore.appIdentifier)
        #expect(store.hasAnyDemonstration)
    }

    @Test func multipleClearDemonstrationsRaiseEstimatedLevel() {
        // UserFEDCProfile.estimatedLevel() picks the highest level for which
        // at least two `.clear`-or-better demonstrations exist. Pin the
        // forwarded semantic so future ForgeDevelopmental changes that move
        // the rule break a focused MicrobeLab test rather than failing in
        // the consuming surface.
        let store = DIRSupportProfileStore(defaults: Self.makeIsolatedDefaults())
        store.recordDemonstration(level: .multiCausalThinking, context: .task, confidence: .clear)
        store.recordDemonstration(level: .multiCausalThinking, context: .task, confidence: .clear)
        #expect(store.currentLevel == .multiCausalThinking)
    }

    @Test func singleSpeculativeDemonstrationFallsBackToMaxLevel() {
        // Single speculative demonstration doesn't meet the 2-clear-or-better
        // threshold; estimatedLevel() falls back to the max demonstrated level.
        let store = DIRSupportProfileStore(defaults: Self.makeIsolatedDefaults())
        store.recordDemonstration(level: .reflectiveThinking, context: .conversation, confidence: .speculative)
        #expect(store.currentLevel == .reflectiveThinking)
    }

    @Test func estimatedBandResolves() {
        let store = DIRSupportProfileStore(defaults: Self.makeIsolatedDefaults())
        store.recordDemonstration(level: .reflectiveThinking, context: .reflection, confidence: .clear)
        store.recordDemonstration(level: .reflectiveThinking, context: .reflection, confidence: .clear)
        #expect(store.estimatedBand != nil)
    }

    @Test func capacityCeilingEvictsOldest() {
        let store = DIRSupportProfileStore(defaults: Self.makeIsolatedDefaults())
        for _ in 0..<(DIRSupportProfileStore.capacity + 5) {
            store.recordDemonstration(level: .twoWayCommunication, context: .task, confidence: .clear)
        }
        #expect(store.profile.demonstrations.count == DIRSupportProfileStore.capacity)
    }

    @Test func persistenceRoundtripsAcrossInstances() {
        let defaults = Self.makeIsolatedDefaults()
        let writer = DIRSupportProfileStore(defaults: defaults)
        writer.recordDemonstration(level: .complexCommunication, context: .conversation, confidence: .robust)
        let reader = DIRSupportProfileStore(defaults: defaults)
        #expect(reader.profile.demonstrations.count == 1)
        #expect(reader.profile.demonstrations.first?.fedcLevel == .complexCommunication)
        #expect(reader.profile.demonstrations.first?.confidence == .robust)
    }

    @Test func clearWipesProfile() {
        let store = DIRSupportProfileStore(defaults: Self.makeIsolatedDefaults())
        store.recordDemonstration(level: .creatingEmotionalIdeas, context: .task, confidence: .clear)
        #expect(!store.profile.demonstrations.isEmpty)
        store.clear()
        #expect(store.profile.demonstrations.isEmpty)
        #expect(!store.hasAnyDemonstration)
    }

    @Test func clearRemovesPersistedData() {
        let defaults = Self.makeIsolatedDefaults()
        let writer = DIRSupportProfileStore(defaults: defaults)
        writer.recordDemonstration(level: .twoWayCommunication, context: .task, confidence: .clear)
        writer.clear()
        let reader = DIRSupportProfileStore(defaults: defaults)
        #expect(reader.profile.demonstrations.isEmpty)
    }

    @Test func appIdentifierMatchesBundleConstant() {
        // Pin the bundle ID constant so a future rename can't silently
        // produce demonstrations with the wrong app identifier.
        #expect(DIRSupportProfileStore.appIdentifier == "com.microbelab.app")
    }

    @Test func capacityIsLoadBearingConstant() {
        // 100 is documented in the doc-comment as the balance point between
        // "enough density for stable level estimation" + "small enough to
        // stay under a few hundred bytes". Pin so a future edit can't change
        // it without breaking this test.
        #expect(DIRSupportProfileStore.capacity == 100)
    }

    @Test func corruptPayloadStartsFresh() {
        // Hydration tolerates corrupt payloads (forward-incompatible JSON
        // future-rev) by starting fresh. Pin the soft-failure semantic.
        let defaults = Self.makeIsolatedDefaults()
        defaults.set("not json".data(using: .utf8), forKey: "microbelab.engagement.dirProfile")
        let store = DIRSupportProfileStore(defaults: defaults)
        #expect(store.profile.demonstrations.isEmpty)
    }
}
