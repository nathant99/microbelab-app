import Foundation
import Testing
@testable import Services

@Suite("MentorRecallStore")
@MainActor
struct MentorRecallStoreTests {
    /// Per `.claude/rules/testing.md` § Crash-Resilience Defaults — every
    /// UserDefaults-using test isolates to a per-file suite + wipes it on
    /// init so cross-test pollution can't leak.
    private static func makeIsolatedDefaults(_ suite: String = #function) -> UserDefaults {
        let defaults = UserDefaults(suiteName: "MentorRecallStoreTests-\(suite)") ?? .standard
        defaults.removePersistentDomain(forName: "MentorRecallStoreTests-\(suite)")
        return defaults
    }

    @Test func freshStoreIsEmpty() {
        let store = MentorRecallStore(defaults: Self.makeIsolatedDefaults())
        #expect(store.entries.isEmpty)
        #expect(store.mostRecent == nil)
        #expect(store.entry(for: 0) == nil)
    }

    @Test func recordAddsEntryAtFront() {
        let store = MentorRecallStore(defaults: Self.makeIsolatedDefaults())
        let now = Date()
        store.record(slug: "lacto", at: now)
        #expect(store.entries.count == 1)
        #expect(store.mostRecent?.slug == "lacto")
        #expect(store.mostRecent?.lastSeenAt == now)
    }

    @Test func duplicateSlugReBumpsToFront() {
        let store = MentorRecallStore(defaults: Self.makeIsolatedDefaults())
        store.record(slug: "lacto")
        store.record(slug: "bif")
        store.record(slug: "lacto")
        // Lacto re-recorded bumps it to the head, doesn't accumulate.
        #expect(store.entries.count == 2)
        #expect(store.mostRecent?.slug == "lacto")
        #expect(store.entries[1].slug == "bif")
    }

    @Test func capacityCapsAtFiveEntries() {
        let store = MentorRecallStore(defaults: Self.makeIsolatedDefaults())
        let slugs = ["a", "b", "c", "d", "e", "f", "g"]
        for slug in slugs {
            store.record(slug: slug)
        }
        #expect(store.entries.count == MentorRecallStore.capacity)
        // Oldest entries dropped FIFO; newest (g) at front.
        #expect(store.entries.first?.slug == "g")
    }

    @Test func recordSkipsEmptySlugs() {
        let store = MentorRecallStore(defaults: Self.makeIsolatedDefaults())
        store.record(slug: "")
        #expect(store.entries.isEmpty)
    }

    @Test func rotationIsDeterministic() {
        let store = MentorRecallStore(defaults: Self.makeIsolatedDefaults())
        store.record(slug: "lacto")
        store.record(slug: "bif")
        store.record(slug: "yeast")
        let firstPickA = store.entry(for: 0)?.slug
        let firstPickB = store.entry(for: 0)?.slug
        #expect(firstPickA == firstPickB)
        let secondPick = store.entry(for: 1)?.slug
        let thirdPick = store.entry(for: 2)?.slug
        // 3 entries, rotations 0/1/2 must all resolve to distinct slugs.
        #expect(Set([firstPickA, secondPick, thirdPick].compactMap { $0 }).count == 3)
    }

    @Test func clearWipesEntries() {
        let store = MentorRecallStore(defaults: Self.makeIsolatedDefaults())
        store.record(slug: "lacto")
        store.record(slug: "bif")
        store.clear()
        #expect(store.entries.isEmpty)
    }

    @Test func persistsAcrossInstances() {
        let defaults = Self.makeIsolatedDefaults()
        do {
            let store = MentorRecallStore(defaults: defaults)
            store.record(slug: "lacto")
            store.record(slug: "bif")
        }
        let rehydrated = MentorRecallStore(defaults: defaults)
        #expect(rehydrated.entries.count == 2)
        #expect(rehydrated.mostRecent?.slug == "bif")
    }
}
