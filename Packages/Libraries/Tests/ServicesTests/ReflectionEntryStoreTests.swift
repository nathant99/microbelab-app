import Foundation
import Testing
import ForgeModels
@testable import Services

@Suite("ReflectionEntryStore")
@MainActor
struct ReflectionEntryStoreTests {
    /// Per `.claude/rules/testing.md` § Crash-Resilience Defaults — every
    /// UserDefaults-using test isolates to a per-file suite + wipes it on
    /// init so cross-test pollution can't leak.
    private static func makeIsolatedDefaults(_ suite: String = #function) -> UserDefaults {
        let defaults = UserDefaults(suiteName: "ReflectionEntryStoreTests-\(suite)") ?? .standard
        defaults.removePersistentDomain(forName: "ReflectionEntryStoreTests-\(suite)")
        return defaults
    }

    private static func makeEntry(
        modality: ReflectionResponseModality = .text,
        text: String? = "Saw a Lacto today",
        promptID: String = "microbelab.reflection.sessionClose",
        at date: Date = .now
    ) -> ReflectionEntry {
        ReflectionEntry(
            promptID: promptID,
            appIdentifier: "com.microbelab.app",
            modality: modality,
            textValue: text,
            respondedAt: date
        )
    }

    @Test func freshStoreIsEmpty() {
        let store = ReflectionEntryStore(defaults: Self.makeIsolatedDefaults())
        #expect(store.entries.isEmpty)
    }

    @Test func appendAddsEntryInOrder() {
        let store = ReflectionEntryStore(defaults: Self.makeIsolatedDefaults())
        let first = Self.makeEntry(text: "First")
        let second = Self.makeEntry(text: "Second")
        store.append(first)
        store.append(second)
        #expect(store.entries.count == 2)
        #expect(store.entries[0].textValue == "First")
        #expect(store.entries[1].textValue == "Second")
    }

    @Test func capacityCeilingEvictsOldest() {
        let store = ReflectionEntryStore(defaults: Self.makeIsolatedDefaults())
        // Append capacity + 5 entries. Expect FIFO eviction down to the
        // capacity ceiling, with the OLDEST 5 dropped.
        let total = ReflectionEntryStore.capacity + 5
        for i in 0..<total {
            store.append(Self.makeEntry(text: "entry-\(i)"))
        }
        #expect(store.entries.count == ReflectionEntryStore.capacity)
        // After eviction the surviving first entry should be entry-5 +
        // the last should be entry-(total-1).
        #expect(store.entries.first?.textValue == "entry-5")
        #expect(store.entries.last?.textValue == "entry-\(total - 1)")
    }

    @Test func entriesForPromptIDFiltersByID() {
        let store = ReflectionEntryStore(defaults: Self.makeIsolatedDefaults())
        store.append(Self.makeEntry(text: "session", promptID: "microbelab.reflection.sessionClose"))
        store.append(Self.makeEntry(text: "kit-1", promptID: "microbelab.reflection.kit.01"))
        store.append(Self.makeEntry(text: "session-2", promptID: "microbelab.reflection.sessionClose"))
        let sessionEntries = store.entries(forPromptID: "microbelab.reflection.sessionClose")
        #expect(sessionEntries.count == 2)
        #expect(sessionEntries.allSatisfy { $0.promptID == "microbelab.reflection.sessionClose" })
        let kitEntries = store.entries(forPromptID: "microbelab.reflection.kit.01")
        #expect(kitEntries.count == 1)
    }

    @Test func purgeOlderThanRemovesOldEntries() {
        let store = ReflectionEntryStore(defaults: Self.makeIsolatedDefaults())
        let now = Date()
        let old = Self.makeEntry(text: "ancient", at: now.addingTimeInterval(-100_000))
        let recent = Self.makeEntry(text: "recent", at: now)
        store.append(old)
        store.append(recent)
        let cutoff = now.addingTimeInterval(-50_000)
        let removed = store.purge(olderThan: cutoff)
        #expect(removed == 1)
        #expect(store.entries.count == 1)
        #expect(store.entries.first?.textValue == "recent")
    }

    @Test func purgeWithNothingToRemoveReturnsZero() {
        let store = ReflectionEntryStore(defaults: Self.makeIsolatedDefaults())
        store.append(Self.makeEntry(text: "fresh"))
        let removed = store.purge(olderThan: .distantPast)
        #expect(removed == 0)
        #expect(store.entries.count == 1)
    }

    @Test func clearWipesAllEntries() {
        let store = ReflectionEntryStore(defaults: Self.makeIsolatedDefaults())
        store.append(Self.makeEntry(text: "one"))
        store.append(Self.makeEntry(text: "two"))
        store.clear()
        #expect(store.entries.isEmpty)
    }

    @Test func persistenceRoundtripsAcrossInstances() {
        let defaults = Self.makeIsolatedDefaults()
        do {
            let store = ReflectionEntryStore(defaults: defaults)
            store.append(Self.makeEntry(text: "persisted-1"))
            store.append(Self.makeEntry(text: "persisted-2"))
        }
        // Fresh instance reading the same defaults must hydrate the
        // same entries. This is the cross-cold-launch persistence
        // guarantee the kid sees as "my reflections stuck around".
        let reread = ReflectionEntryStore(defaults: defaults)
        #expect(reread.entries.count == 2)
        #expect(reread.entries.map(\.textValue) == ["persisted-1", "persisted-2"])
    }

    @Test func corruptPayloadStartsFresh() {
        let defaults = Self.makeIsolatedDefaults()
        // Seed defaults with a payload the decoder will reject.
        let garbage = "not-json-at-all".data(using: .utf8)!
        defaults.set(garbage, forKey: "microbelab.engagement.reflectionEntries")
        let store = ReflectionEntryStore(defaults: defaults)
        // Per the policy: corrupt payload drops quietly + the store
        // starts fresh rather than crashing. The kid loses prior
        // reflections (soft loss) but the app keeps running.
        #expect(store.entries.isEmpty)
    }

    @Test func skipEntriesRoundtripWithoutText() {
        let store = ReflectionEntryStore(defaults: Self.makeIsolatedDefaults())
        let skip = ReflectionEntry.skip(
            promptID: "microbelab.reflection.sessionClose",
            appIdentifier: "com.microbelab.app"
        )
        store.append(skip)
        #expect(store.entries.count == 1)
        #expect(store.entries.first?.modality == .skip)
        #expect(store.entries.first?.textValue == nil)
    }
}
