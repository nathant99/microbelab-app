import Foundation
import Testing
@testable import Services
@testable import Models

@Suite("MicrobeSpotlightItem")
struct MicrobeSpotlightItemTests {
    private func makeMicrobe(slug: String = "lacto", displayName: String = "Lacto") -> MicrobeCharacter {
        MicrobeCharacter(
            id: UUID(),
            slug: slug,
            displayName: displayName,
            kingdom: .bacteria,
            role: .beneficial,
            preferredEnvironment: .smallIntestine,
            growthRate: GrowthRate(onFiber: 0.4, onSugar: -0.1, onBalanced: 0.2, onNone: 0.0),
            catchphrase: "Keep the fiber coming — I'm thriving.",
            factCard: "Lactobacillus ferments dietary fiber into short-chain fatty acids.",
            firstKit: 1,
            voiceLines: ["Fiber feeds me.", "I'm a quiet helper."]
        )
    }

    @Test func spotlightIDUsesSlugForStability() {
        let microbe = makeMicrobe(slug: "lacto")
        let item = MicrobeSpotlightItem(microbe: microbe)
        #expect(item.spotlightID == "microbelab.codex.lacto")
    }

    @Test func spotlightIDStaysStableAcrossUUIDChurn() {
        // Two microbes that share a slug but have different UUIDs (e.g.,
        // after a catalog rehydrate from a remote) must still resolve to the
        // same Spotlight identity. Without this stability the index would
        // accumulate orphan rows.
        let microbe1 = makeMicrobe(slug: "lacto")
        let microbe2 = makeMicrobe(slug: "lacto")
        #expect(microbe1.id != microbe2.id)
        #expect(MicrobeSpotlightItem(microbe: microbe1).spotlightID
                == MicrobeSpotlightItem(microbe: microbe2).spotlightID)
    }

    @Test func spotlightTitleEqualsDisplayName() {
        let microbe = makeMicrobe(displayName: "Lacto")
        let item = MicrobeSpotlightItem(microbe: microbe)
        #expect(item.spotlightTitle == "Lacto")
    }

    @Test func spotlightDescriptionMergesCatchphraseAndFactCard() {
        let microbe = makeMicrobe()
        let item = MicrobeSpotlightItem(microbe: microbe)
        #expect(item.spotlightDescription.contains(microbe.catchphrase))
        #expect(item.spotlightDescription.contains(microbe.factCard))
    }

    @Test func spotlightKeywordsIncludeSlugDisplayKingdomRoleEnvironment() {
        let microbe = makeMicrobe(slug: "lacto", displayName: "Lacto")
        let keywords = MicrobeSpotlightItem(microbe: microbe).spotlightKeywords
        #expect(keywords.contains("lacto"))
        #expect(keywords.contains("Lacto"))
        #expect(keywords.contains(MicrobeKingdom.bacteria.rawValue))
        #expect(keywords.contains(MicrobeRole.beneficial.rawValue))
        #expect(keywords.contains(GutSlot.smallIntestine.rawValue))
    }

    @Test func spotlightKeywordsContainOnlyStableEnumSlugs() {
        // PII discipline — keywords must never include a kid-identifying
        // token (no displayName-derived text beyond the microbe's name).
        let microbe = makeMicrobe()
        let keywords = MicrobeSpotlightItem(microbe: microbe).spotlightKeywords
        // Every keyword is either the microbe's own slug/display or a
        // catalog-derived enum rawValue.
        let allowedKingdomSlugs = Set(MicrobeKingdom.allCases.map(\.rawValue))
        let allowedRoleSlugs = Set(MicrobeRole.allCases.map(\.rawValue))
        let allowedEnvironmentSlugs = Set(GutSlot.allCases.map(\.rawValue))
        for keyword in keywords {
            let isOwnIdentity = keyword == microbe.slug || keyword == microbe.displayName
            let isCatalogSlug = allowedKingdomSlugs.contains(keyword)
                || allowedRoleSlugs.contains(keyword)
                || allowedEnvironmentSlugs.contains(keyword)
            #expect(isOwnIdentity || isCatalogSlug,
                    "Spotlight keyword '\(keyword)' leaks non-catalog data")
        }
    }
}

@Suite("MicrobeSpotlightIndex")
@MainActor
struct MicrobeSpotlightIndexLifecycleTests {
    @Test func initialStateIsEmpty() {
        let index = MicrobeSpotlightIndex()
        #expect(index.lastIndexedSlugs.isEmpty)
        #expect(index.lastIndexError == nil)
    }
}
