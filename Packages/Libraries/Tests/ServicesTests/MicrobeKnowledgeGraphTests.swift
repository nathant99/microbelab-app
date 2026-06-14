import Testing
import Foundation
import Models
@testable import Services

@Suite("MicrobeKnowledgeGraph (ForgeKnowledgeGraph wrapper)")
struct MicrobeKnowledgeGraphTests {

    private func makeMicrobe(
        slug: String,
        displayName: String,
        environment: GutSlot,
        role: MicrobeRole = .beneficial,
        kingdom: MicrobeKingdom = .bacteria,
        firstKit: Int = 1
    ) -> MicrobeCharacter {
        MicrobeCharacter(
            id: UUID(),
            slug: slug,
            displayName: displayName,
            kingdom: kingdom,
            role: role,
            preferredEnvironment: environment,
            growthRate: GrowthRate(onFiber: 0.5, onSugar: -0.2, onBalanced: 0.2, onNone: 0),
            catchphrase: "Hi",
            factCard: "Fact",
            firstKit: firstKit
        )
    }

    // MARK: - v1 shared-habitat behavior (preserved across the 17th-pass extension)

    @Test("empty catalog yields a zero-node, zero-edge graph")
    func emptyCatalog() {
        let g = MicrobeKnowledgeGraph(microbes: [])
        #expect(g.nodeCount == 0)
        #expect(g.edgeCount == 0)
        #expect(g.related(toSlug: "lacto") == [])
    }

    @Test("single-microbe catalog has 1 node, 0 edges")
    func singleMicrobeCatalog() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", environment: .colon)
        let g = MicrobeKnowledgeGraph(microbes: [lacto])
        #expect(g.nodeCount == 1)
        #expect(g.edgeCount == 0)
        #expect(g.related(to: lacto) == [])
    }

    @Test("two microbes in the same slot — related() returns the habitat neighbor only")
    func twoMicrobesSameSlot_relatedByHabitat() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", environment: .colon)
        let bifido = makeMicrobe(slug: "bifido", displayName: "Bifido", environment: .colon)
        let g = MicrobeKnowledgeGraph(microbes: [lacto, bifido])
        #expect(g.nodeCount == 2)

        let lactoNeighbors = g.related(to: lacto)
        #expect(lactoNeighbors.map(\.slug) == ["bifido"])

        let bifidoNeighbors = g.related(to: bifido)
        #expect(bifidoNeighbors.map(\.slug) == ["lacto"])
    }

    @Test("three microbes in same slot — each has the other two as habitat neighbors")
    func threeMicrobesSameSlot_relatedByHabitat() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", environment: .colon)
        let bifido = makeMicrobe(slug: "bifido", displayName: "Bifido", environment: .colon)
        let akker = makeMicrobe(slug: "akker", displayName: "Akker", environment: .colon)

        let g = MicrobeKnowledgeGraph(microbes: [lacto, bifido, akker])
        #expect(g.nodeCount == 3)

        // Alphabetic ordering preserved: akker → [bifido, lacto]
        #expect(g.related(to: akker).map(\.slug) == ["bifido", "lacto"])
        #expect(g.related(to: bifido).map(\.slug) == ["akker", "lacto"])
        #expect(g.related(to: lacto).map(\.slug) == ["akker", "bifido"])
    }

    @Test("microbes in different slots have no habitat edge between them — related() returns []")
    func differentSlots_noHabitatRelation() {
        // Distinct role + kingdom so role/kingdom cohorts don't leak into related().
        let oral = makeMicrobe(
            slug: "strep", displayName: "Strep", environment: .oralCavity,
            role: .opportunistic, kingdom: .bacteria
        )
        let colon = makeMicrobe(
            slug: "lacto", displayName: "Lacto", environment: .colon,
            role: .beneficial, kingdom: .bacteria
        )

        let g = MicrobeKnowledgeGraph(microbes: [oral, colon])
        #expect(g.nodeCount == 2)
        #expect(g.related(to: oral) == [])
        #expect(g.related(to: colon) == [])
    }

    @Test("related(limit:) honors the cap")
    func relatedHonorsLimit() {
        let a = makeMicrobe(slug: "a", displayName: "A", environment: .colon)
        let b = makeMicrobe(slug: "b", displayName: "B", environment: .colon)
        let c = makeMicrobe(slug: "c", displayName: "C", environment: .colon)
        let d = makeMicrobe(slug: "d", displayName: "D", environment: .colon)

        let g = MicrobeKnowledgeGraph(microbes: [a, b, c, d])
        let aNeighbors = g.related(to: a, limit: 2)
        #expect(aNeighbors.count == 2)
        #expect(aNeighbors.map(\.slug) == ["b", "c"]) // alphabetic
    }

    @Test("related ignores the queried microbe itself even if it appears in the slot")
    func excludesSelf() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", environment: .colon)
        let bifido = makeMicrobe(slug: "bifido", displayName: "Bifido", environment: .colon)
        let g = MicrobeKnowledgeGraph(microbes: [lacto, bifido])
        let lactoNeighbors = g.related(to: lacto)
        #expect(!lactoNeighbors.contains(where: { $0.slug == "lacto" }))
    }

    @Test("related(toSlug:) returns empty for an unknown slug rather than crashing")
    func unknownSlugReturnsEmpty() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", environment: .colon)
        let g = MicrobeKnowledgeGraph(microbes: [lacto])
        #expect(g.related(toSlug: "not-in-catalog") == [])
    }

    // MARK: - Role + kingdom cohort edges (17th-pass extension)

    @Test("relatedByRole — two beneficials in different slots are role-cohort neighbors")
    func relatedByRole_crossSlot() {
        let lacto = makeMicrobe(
            slug: "lacto", displayName: "Lacto", environment: .colon,
            role: .beneficial, kingdom: .bacteria
        )
        let yeast = makeMicrobe(
            slug: "yeast", displayName: "Yeast", environment: .skin,
            role: .beneficial, kingdom: .fungi
        )
        let g = MicrobeKnowledgeGraph(microbes: [lacto, yeast])

        // Habitat-distinct, role-shared, kingdom-distinct.
        #expect(g.related(to: lacto) == [])
        #expect(g.relatedByRole(to: lacto).map(\.slug) == ["yeast"])
        #expect(g.relatedByKingdom(to: lacto) == [])
    }

    @Test("relatedByKingdom — two bacteria in different slots are kingdom-cohort neighbors")
    func relatedByKingdom_crossSlot() {
        let lacto = makeMicrobe(
            slug: "lacto", displayName: "Lacto", environment: .colon,
            role: .beneficial, kingdom: .bacteria
        )
        let strep = makeMicrobe(
            slug: "strep", displayName: "Strep", environment: .oralCavity,
            role: .opportunistic, kingdom: .bacteria
        )
        let g = MicrobeKnowledgeGraph(microbes: [lacto, strep])

        #expect(g.related(to: lacto) == []) // different slots
        #expect(g.relatedByRole(to: lacto) == []) // different roles
        #expect(g.relatedByKingdom(to: lacto).map(\.slug) == ["strep"])
    }

    @Test("relatedByRole + relatedByKingdom honor alphabetic ordering + self-exclusion")
    func cohortOrderingAndSelfExclusion() {
        let a = makeMicrobe(
            slug: "a", displayName: "A", environment: .colon,
            role: .beneficial, kingdom: .bacteria
        )
        let c = makeMicrobe(
            slug: "c", displayName: "C", environment: .skin,
            role: .beneficial, kingdom: .bacteria
        )
        let b = makeMicrobe(
            slug: "b", displayName: "B", environment: .soil,
            role: .beneficial, kingdom: .bacteria
        )
        let g = MicrobeKnowledgeGraph(microbes: [a, b, c])

        // All three same role + kingdom; all three different habitat.
        let roleNeighbors = g.relatedByRole(to: a)
        #expect(roleNeighbors.map(\.slug) == ["b", "c"])
        #expect(!roleNeighbors.contains(where: { $0.slug == "a" }))

        let kingdomNeighbors = g.relatedByKingdom(to: a)
        #expect(kingdomNeighbors.map(\.slug) == ["b", "c"])
        #expect(!kingdomNeighbors.contains(where: { $0.slug == "a" }))
    }

    @Test("relatedByRole(limit:) + relatedByKingdom(limit:) honor the cap")
    func cohortsHonorLimit() {
        let a = makeMicrobe(slug: "a", displayName: "A", environment: .colon)
        let b = makeMicrobe(slug: "b", displayName: "B", environment: .skin)
        let c = makeMicrobe(slug: "c", displayName: "C", environment: .soil)
        let d = makeMicrobe(slug: "d", displayName: "D", environment: .oralCavity)

        // All four default .beneficial + .bacteria.
        let g = MicrobeKnowledgeGraph(microbes: [a, b, c, d])
        let cappedRole = g.relatedByRole(to: a, limit: 2)
        #expect(cappedRole.map(\.slug) == ["b", "c"])

        let cappedKingdom = g.relatedByKingdom(to: a, limit: 2)
        #expect(cappedKingdom.map(\.slug) == ["b", "c"])
    }

    @Test("relatedByRole / relatedByKingdom return [] for an unknown slug")
    func unknownSlugCohortsReturnEmpty() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", environment: .colon)
        let g = MicrobeKnowledgeGraph(microbes: [lacto])
        #expect(g.relatedByRole(toSlug: "not-in-catalog") == [])
        #expect(g.relatedByKingdom(toSlug: "not-in-catalog") == [])
    }

    // MARK: - allRelated — deduplicated union across all three edge classes

    @Test("allRelated unions habitat + role + kingdom dedup'd by slug")
    func allRelatedUnion() {
        let lacto = makeMicrobe(
            slug: "lacto", displayName: "Lacto", environment: .colon,
            role: .beneficial, kingdom: .bacteria
        )
        let bifido = makeMicrobe(
            slug: "bifido", displayName: "Bifido", environment: .colon,
            role: .beneficial, kingdom: .bacteria
        )
        let yeast = makeMicrobe(
            slug: "yeast", displayName: "Yeast", environment: .skin,
            role: .beneficial, kingdom: .fungi
        )
        let strep = makeMicrobe(
            slug: "strep", displayName: "Strep", environment: .oralCavity,
            role: .opportunistic, kingdom: .bacteria
        )

        let g = MicrobeKnowledgeGraph(microbes: [lacto, bifido, yeast, strep])

        // bifido (habitat) + yeast (role) + strep (kingdom) — three distinct slugs.
        let union = g.allRelated(to: lacto)
        #expect(union.map(\.slug) == ["bifido", "strep", "yeast"]) // alphabetic
        #expect(union.count == 3) // dedup'd; bifido appears via habitat AND role AND kingdom but counted once
    }

    @Test("allRelated(limit:) caps the dedup'd union")
    func allRelatedHonorsLimit() {
        let a = makeMicrobe(slug: "a", displayName: "A", environment: .colon)
        let b = makeMicrobe(slug: "b", displayName: "B", environment: .colon)
        let c = makeMicrobe(slug: "c", displayName: "C", environment: .colon)
        let d = makeMicrobe(slug: "d", displayName: "D", environment: .colon)

        let g = MicrobeKnowledgeGraph(microbes: [a, b, c, d])
        let capped = g.allRelated(to: a, limit: 2)
        #expect(capped.count == 2)
        #expect(capped.map(\.slug) == ["b", "c"])
    }

    @Test("allRelated returns [] for an unknown slug")
    func allRelatedUnknownSlugReturnsEmpty() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", environment: .colon)
        let g = MicrobeKnowledgeGraph(microbes: [lacto])
        #expect(g.allRelated(toSlug: "not-in-catalog") == [])
    }

    @Test("allRelated excludes self even when self matches all three dimensions")
    func allRelatedExcludesSelf() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", environment: .colon)
        let bifido = makeMicrobe(slug: "bifido", displayName: "Bifido", environment: .colon)
        let g = MicrobeKnowledgeGraph(microbes: [lacto, bifido])
        #expect(!g.allRelated(to: lacto).contains(where: { $0.slug == "lacto" }))
    }

    // MARK: - Edge count invariants (sanity check on the layered emission)

    @Test("edgeCount sums all three edge classes; non-zero across role+kingdom cohorts")
    func edgeCountSumsAllClasses() {
        // Two microbes in different slots but same role + same kingdom.
        // Habitat: 0 edges. Role: 2 edges. Kingdom: 2 edges. Total: 4.
        let lacto = makeMicrobe(
            slug: "lacto", displayName: "Lacto", environment: .colon,
            role: .beneficial, kingdom: .bacteria
        )
        let bifido = makeMicrobe(
            slug: "bifido", displayName: "Bifido", environment: .skin,
            role: .beneficial, kingdom: .bacteria
        )
        let g = MicrobeKnowledgeGraph(microbes: [lacto, bifido])
        #expect(g.edgeCount == 4)
    }

    @Test("edgeCount is zero when no two microbes share any dimension")
    func edgeCountZeroAcrossDistinctDimensions() {
        // Distinct habitat AND distinct role AND distinct kingdom — zero edges.
        let lacto = makeMicrobe(
            slug: "lacto", displayName: "Lacto", environment: .colon,
            role: .beneficial, kingdom: .bacteria
        )
        let yeast = makeMicrobe(
            slug: "yeast", displayName: "Yeast", environment: .skin,
            role: .opportunistic, kingdom: .fungi
        )
        let g = MicrobeKnowledgeGraph(microbes: [lacto, yeast])
        #expect(g.edgeCount == 0)
    }
}
