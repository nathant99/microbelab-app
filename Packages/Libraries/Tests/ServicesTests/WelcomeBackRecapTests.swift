import Testing
import Foundation
@testable import Services
@testable import Models

/// Pins the trauma-informed posture + determinism + per-`daysAway` selection
/// invariants on the welcome-back recap surface.
@Suite("WelcomeBackRecap")
struct WelcomeBackRecapTests {

    // MARK: - Fixtures

    /// Minimal-but-realistic catalog matching the canonical 6-character DN
    /// cast. Keeps tests deterministic without depending on the bundled
    /// `microbes.json` loader.
    private func fixtureCatalog() -> MicrobeCatalogService {
        let growthRate = GrowthRate(onFiber: 0.5, onSugar: -0.2, onBalanced: 0.2, onNone: -0.5)
        return MicrobeCatalogService(microbes: [
            MicrobeCharacter(id: UUID(), slug: "lacto", displayName: "Lacto", kingdom: .bacteria, role: .beneficial, preferredEnvironment: .smallIntestine, growthRate: growthRate, catchphrase: "I help digest!", factCard: "Lactobacillus helps your gut.", firstKit: 1),
            MicrobeCharacter(id: UUID(), slug: "yeast", displayName: "Yeast", kingdom: .fungi, role: .beneficial, preferredEnvironment: .colon, growthRate: growthRate, catchphrase: "I rise!", factCard: "Yeast makes bread rise.", firstKit: 1),
            MicrobeCharacter(id: UUID(), slug: "photo", displayName: "Photo", kingdom: .bacteria, role: .beneficial, preferredEnvironment: .skin, growthRate: growthRate, catchphrase: "I love sunlight!", factCard: "Photosynthetic.", firstKit: 2),
            MicrobeCharacter(id: UUID(), slug: "net", displayName: "Net", kingdom: .bacteria, role: .neutral, preferredEnvironment: .oralCavity, growthRate: growthRate, catchphrase: "I network!", factCard: "Form biofilms.", firstKit: 2),
            MicrobeCharacter(id: UUID(), slug: "spore", displayName: "Spore", kingdom: .bacteria, role: .neutral, preferredEnvironment: .largeIntestine, growthRate: growthRate, catchphrase: "I sleep!", factCard: "Dormant.", firstKit: 3),
            MicrobeCharacter(id: UUID(), slug: "guard", displayName: "Guard", kingdom: .bacteria, role: .beneficial, preferredEnvironment: .colon, growthRate: growthRate, catchphrase: "I protect!", factCard: "Guards mucus.", firstKit: 3),
        ])
    }

    // MARK: - Discovery gates

    @Test("Returns nil when discovery set is empty")
    func emptyDiscoverySetReturnsNil() {
        let recap = WelcomeBackRecap.from(
            discoveredSlugs: [],
            catalog: fixtureCatalog(),
            daysAway: 4
        )
        #expect(recap == nil)
    }

    @Test("Returns nil when all discovered slugs are unknown to catalog")
    func staleSlugsReturnNil() {
        // Simulates a catalog version bump that removed these slugs;
        // defensive against persisted-state drift.
        let recap = WelcomeBackRecap.from(
            discoveredSlugs: ["stale_microbe_1", "stale_microbe_2"],
            catalog: fixtureCatalog(),
            daysAway: 4
        )
        #expect(recap == nil)
    }

    @Test("Falls back gracefully when only one of N slugs is known")
    func partiallyKnownSlugsReturnsKnownSubset() {
        let recap = WelcomeBackRecap.from(
            discoveredSlugs: ["lacto", "stale_unknown"],
            catalog: fixtureCatalog(),
            daysAway: 5
        )
        guard let recap else {
            Issue.record("Expected a non-nil recap with at least the known slug")
            return
        }
        #expect(recap.recalledMicrobeDisplayNames.count == 1)
        #expect(recap.recalledMicrobeDisplayNames.first == "Lacto")
    }

    // MARK: - Selection invariants

    @Test("Recall count is clamped to 2 even when many microbes are known")
    func recallCountClampedToTwo() {
        let recap = WelcomeBackRecap.from(
            discoveredSlugs: ["lacto", "yeast", "photo", "net", "spore", "guard"],
            catalog: fixtureCatalog(),
            daysAway: 7
        )
        guard let recap else {
            Issue.record("Expected a non-nil recap with all 6 microbes known")
            return
        }
        #expect(recap.recalledMicrobeDisplayNames.count == 2)
    }

    @Test("Selection is deterministic per daysAway — same daysAway → same picks")
    func selectionIsDeterministicPerDaysAway() {
        let catalog = fixtureCatalog()
        let allKnown: Set<String> = ["lacto", "yeast", "photo", "net", "spore", "guard"]
        let r1 = WelcomeBackRecap.from(discoveredSlugs: allKnown, catalog: catalog, daysAway: 4)
        let r2 = WelcomeBackRecap.from(discoveredSlugs: allKnown, catalog: catalog, daysAway: 4)
        let r3 = WelcomeBackRecap.from(discoveredSlugs: allKnown, catalog: catalog, daysAway: 4)
        #expect(r1 == r2)
        #expect(r2 == r3)
    }

    @Test("Different daysAway values can yield different picks (mixer is sensitive)")
    func differentDaysAwayCanYieldDifferentPicks() {
        let catalog = fixtureCatalog()
        let allKnown: Set<String> = ["lacto", "yeast", "photo", "net", "spore", "guard"]
        // Across daysAway values 3-20, at least 2 distinct pick-pairs
        // should surface — guarantees the mixer is doing something.
        var distinctPicks: Set<[String]> = []
        for days in 3...20 {
            if let r = WelcomeBackRecap.from(discoveredSlugs: allKnown, catalog: catalog, daysAway: days) {
                distinctPicks.insert(r.recalledMicrobeDisplayNames)
            }
        }
        #expect(distinctPicks.count >= 2, "Mixer produced too few distinct picks across daysAway range")
    }

    @Test("Picks are uniqued — never repeats the same microbe twice")
    func picksAreUnique() {
        let recap = WelcomeBackRecap.from(
            discoveredSlugs: ["lacto", "yeast"],
            catalog: fixtureCatalog(),
            daysAway: 5
        )
        guard let recap else {
            Issue.record("Expected non-nil recap")
            return
        }
        let names = recap.recalledMicrobeDisplayNames
        #expect(Set(names).count == names.count, "Recap picked the same microbe twice")
    }

    // MARK: - Trauma-informed copy invariants

    @Test("Lead-in copy NEVER uses loss-aversion / abandonment / shame language")
    func leadInCopyStoplistPassesAcrossDaysRange() {
        // Stoplist mirrors the canonical trauma-informed posture per
        // .claude/rules/distributed-narrative.md § Audience register.
        // The recap is a warm callback — never accusatory, never
        // benchmarking absence as failure.
        let stoplist = [
            "missed",
            "abandon",
            "forgot",
            "failed",
            "should have",
            "behind",
            "neglect",
            "shame",
            "fell short",
            "compared",
            "better than",
            "lost",
            "didn't",
        ]
        for days in 1...60 {
            for count in 0...2 {
                let copy = WelcomeBackRecap.leadInCopy(forDaysAway: days, recalledCount: count).lowercased()
                for token in stoplist {
                    #expect(!copy.contains(token), "leadInCopy for days=\(days) count=\(count) contained stoplist token '\(token)': \"\(copy)\"")
                }
            }
        }
    }

    @Test("Lead-in copy varies between single- and multi-microbe recap")
    func leadInCopyVariesByRecalledCount() {
        let one = WelcomeBackRecap.leadInCopy(forDaysAway: 4, recalledCount: 1)
        let two = WelcomeBackRecap.leadInCopy(forDaysAway: 4, recalledCount: 2)
        #expect(one != two, "Lead-in copy should differ between 1-microbe and 2-microbe recall (singular vs plural register)")
    }

    @Test("Single-microbe recall copy uses singular framing")
    func singleMicrobeCopyIsSingularRegister() {
        let copy = WelcomeBackRecap.leadInCopy(forDaysAway: 4, recalledCount: 1)
        // The canonical single-microbe lead-in references "the lens"
        // (microscope register) so the kid maps the recall back to the
        // discovery surface.
        #expect(copy.lowercased().contains("lens"), "Single-microbe lead-in copy should reference the microscope register")
    }
}
