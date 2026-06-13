import Foundation
import Testing
@testable import Services

@Suite("DiscoveryStore")
@MainActor
struct DiscoveryStoreTests {
    /// Per `.claude/rules/testing.md` § Crash-Resilience Defaults — every
    /// UserDefaults-using test isolates to a per-suite name + wipes it on
    /// init so cross-test pollution can't leak.
    private static func makeIsolatedDefaults(_ suite: String = #function) -> UserDefaults {
        let name = "DiscoveryStoreTests-\(suite)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func freshStoreIsEmpty() {
        let store = DiscoveryStore(defaults: Self.makeIsolatedDefaults())
        #expect(store.discoveredSlugs.isEmpty)
    }

    @Test func markDiscoveredAddsSlug() {
        let store = DiscoveryStore(defaults: Self.makeIsolatedDefaults())
        store.markDiscovered(slug: "lacto")
        #expect(store.discoveredSlugs == ["lacto"])
    }

    @Test func markDiscoveredIsIdempotent() {
        let store = DiscoveryStore(defaults: Self.makeIsolatedDefaults())
        store.markDiscovered(slug: "lacto")
        store.markDiscovered(slug: "lacto")
        store.markDiscovered(slug: "lacto")
        #expect(store.discoveredSlugs.count == 1)
    }

    @Test func multipleSlugsAccumulate() {
        let store = DiscoveryStore(defaults: Self.makeIsolatedDefaults())
        for slug in ["lacto", "bif", "akker", "rhino"] {
            store.markDiscovered(slug: slug)
        }
        #expect(store.discoveredSlugs.count == 4)
        #expect(store.discoveredSlugs.contains("lacto"))
        #expect(store.discoveredSlugs.contains("rhino"))
    }

    @Test func slugsPersistAcrossInstances() {
        let defaults = Self.makeIsolatedDefaults()
        let first = DiscoveryStore(defaults: defaults)
        first.markDiscovered(slug: "lacto")
        first.markDiscovered(slug: "bif")

        // Re-hydrate from the same defaults — slugs survive.
        let second = DiscoveryStore(defaults: defaults)
        #expect(second.discoveredSlugs.count == 2)
        #expect(second.discoveredSlugs.contains("lacto"))
        #expect(second.discoveredSlugs.contains("bif"))
    }

    @Test func clearForTestingWipesState() {
        let store = DiscoveryStore(defaults: Self.makeIsolatedDefaults())
        store.markDiscovered(slug: "lacto")
        store.clearForTesting()
        #expect(store.discoveredSlugs.isEmpty)
    }

    @Test func userDefaultsKeyIsStable() {
        // Stability of the persistence key matters for forward-compat —
        // changing it without a migration would orphan kid's prior
        // discovery state. Pin the canonical value.
        #expect(DiscoveryStore.userDefaultsKey == "com.microbelab.discovery.slugs")
    }

    @Test func completionTriggersTwelveDiscoveriesPath() {
        // Mirrors the canonical 12-microbe codex completion path. The
        // store doesn't enforce a max; this test pins that 12 distinct
        // markDiscovered calls produce a set of size 12 so the
        // `MasteryMomentDetector.recordCodexDiscovery(totalDiscovered:
        // totalAvailable:)` codex-mastery axis can fire cleanly when
        // wired through `MicrobeCodexView`.
        let store = DiscoveryStore(defaults: Self.makeIsolatedDefaults())
        let canonicalCast = [
            "lacto", "yeast", "photo", "net", "spore", "guard",
            "bifido", "akker", "strep", "coli", "rhino", "deino"
        ]
        for slug in canonicalCast {
            store.markDiscovered(slug: slug)
        }
        #expect(store.discoveredSlugs.count == 12)
    }
}
