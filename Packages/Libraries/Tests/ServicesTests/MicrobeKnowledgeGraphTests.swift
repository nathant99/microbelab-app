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
        firstKit: Int = 1
    ) -> MicrobeCharacter {
        MicrobeCharacter(
            id: UUID(),
            slug: slug,
            displayName: displayName,
            kingdom: .bacteria,
            role: role,
            preferredEnvironment: environment,
            growthRate: GrowthRate(onFiber: 0.5, onSugar: -0.2, onBalanced: 0.2, onNone: 0),
            catchphrase: "Hi",
            factCard: "Fact",
            firstKit: firstKit
        )
    }

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

    @Test("two microbes in the same slot emit two directed edges")
    func twoMicrobesSameSlot_twoEdges() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", environment: .colon)
        let bifido = makeMicrobe(slug: "bifido", displayName: "Bifido", environment: .colon)
        let g = MicrobeKnowledgeGraph(microbes: [lacto, bifido])
        #expect(g.nodeCount == 2)
        // Directed: lacto→bifido + bifido→lacto = 2 edges (symmetric pair).
        #expect(g.edgeCount == 2)

        let lactoNeighbors = g.related(to: lacto)
        #expect(lactoNeighbors.map(\.slug) == ["bifido"])

        let bifidoNeighbors = g.related(to: bifido)
        #expect(bifidoNeighbors.map(\.slug) == ["lacto"])
    }

    @Test("three microbes in same slot — each has the other two as neighbors")
    func threeMicrobesSameSlot_threeNeighborPairs() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", environment: .colon)
        let bifido = makeMicrobe(slug: "bifido", displayName: "Bifido", environment: .colon)
        let akker = makeMicrobe(slug: "akker", displayName: "Akker", environment: .colon)

        let g = MicrobeKnowledgeGraph(microbes: [lacto, bifido, akker])
        #expect(g.nodeCount == 3)
        // Σ n(n-1) for n=3 → 6 directed edges.
        #expect(g.edgeCount == 6)

        // Alphabetic ordering: akker → [bifido, lacto]
        #expect(g.related(to: akker).map(\.slug) == ["bifido", "lacto"])
        // bifido → [akker, lacto]
        #expect(g.related(to: bifido).map(\.slug) == ["akker", "lacto"])
        // lacto → [akker, bifido]
        #expect(g.related(to: lacto).map(\.slug) == ["akker", "bifido"])
    }

    @Test("microbes in different slots have no edges between them")
    func differentSlots_noEdge() {
        let oral = makeMicrobe(slug: "strep", displayName: "Strep", environment: .oralCavity)
        let colon = makeMicrobe(slug: "lacto", displayName: "Lacto", environment: .colon)

        let g = MicrobeKnowledgeGraph(microbes: [oral, colon])
        #expect(g.nodeCount == 2)
        #expect(g.edgeCount == 0)
        #expect(g.related(to: oral) == [])
        #expect(g.related(to: colon) == [])
    }

    @Test("two slots with two microbes each emit 4 directed edges total")
    func twoSlotsTwoMicrobes_fourEdges() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", environment: .colon)
        let bifido = makeMicrobe(slug: "bifido", displayName: "Bifido", environment: .colon)
        let strep = makeMicrobe(slug: "strep", displayName: "Strep", environment: .oralCavity)
        let net = makeMicrobe(slug: "net", displayName: "Net", environment: .oralCavity)

        let g = MicrobeKnowledgeGraph(microbes: [lacto, bifido, strep, net])
        #expect(g.nodeCount == 4)
        #expect(g.edgeCount == 4)
        #expect(Set(g.related(to: lacto).map(\.slug)) == Set(["bifido"]))
        #expect(Set(g.related(to: strep).map(\.slug)) == Set(["net"]))
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
}
