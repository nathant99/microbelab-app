import Foundation
import Models
import ForgeKnowledgeGraph
import ForgeModels

/// Cross-microbe ecology graph derived from the bundled `MicrobeCatalog`.
/// Wraps a `ForgeKnowledgeGraph.KnowledgeGraph` whose nodes are microbes
/// (keyed by `slug`) and whose edges encode shared-habitat relationships.
///
/// Pure value type per `.claude/rules/concurrency.md` — `nonisolated` so the
/// codex grid (MainActor) and tests (any isolation) can use it without an
/// isolation hop.
///
/// **Why shared-habitat as the v1 edge**: microbes that thrive in the same
/// `GutSlot` (colon / largeIntestine / oralCavity / etc.) literally rub
/// elbows in the kid's body. The Phase 1 codex doesn't carry richer
/// ecology data (e.g., explicit cross-feeding relationships in the
/// catalog JSON), so habitat co-occurrence is the strongest authored
/// signal we can derive without making up biology that isn't on the
/// curriculum. Per `.claude/rules/ai-content.md` we don't generate this
/// from the AI mentor — derivation is from the authored catalog only.
public nonisolated struct MicrobeKnowledgeGraph: Sendable {
    private let graph: KnowledgeGraph
    private let microbesBySlug: [String: MicrobeCharacter]

    /// Builds the graph from a catalog. Shared-habitat edges are emitted
    /// in both directions (i.e., `from: lacto → to: bifido` AND
    /// `from: bifido → to: lacto`) so traversal is symmetric.
    public init(microbes: [MicrobeCharacter]) {
        var slugMap = [String: MicrobeCharacter]()
        var nodes = [KnowledgeNode]()
        nodes.reserveCapacity(microbes.count)
        for microbe in microbes {
            slugMap[microbe.slug] = microbe
            nodes.append(
                KnowledgeNode(
                    id: microbe.slug,
                    title: microbe.displayName,
                    bloomLevel: .understand,
                    topic: microbe.preferredEnvironment.rawValue,
                    subtopic: microbe.role.rawValue,
                    gradeBand: "MS",
                    standards: [],
                    contentKitIDs: ["kit_\(String(format: "%02d", microbe.firstKit))"]
                )
            )
        }
        self.microbesBySlug = slugMap

        var edges = [KnowledgeEdge]()
        // Shared-habitat edges (symmetric, .recommended strength).
        let bySlot = Dictionary(grouping: microbes) { $0.preferredEnvironment }
        for (_, cohort) in bySlot where cohort.count >= 2 {
            for i in 0..<cohort.count {
                for j in 0..<cohort.count where i != j {
                    edges.append(
                        KnowledgeEdge(
                            from: cohort[i].slug,
                            to: cohort[j].slug,
                            strength: .recommended
                        )
                    )
                }
            }
        }
        self.graph = KnowledgeGraph(nodes: nodes, edges: edges)
    }

    /// Total node count — equals the bundled catalog size.
    public var nodeCount: Int { graph.nodeCount }

    /// Total directed edge count — for shared-habitat-only graphs this is
    /// `Σ_slot n(n-1)` over slots with at least 2 microbes.
    public var edgeCount: Int { graph.edgeCount }

    /// Returns up to `limit` microbe characters related to `slug` via the
    /// shared-habitat graph. Determinism-by-slug: alphabetic ordering on
    /// the slug breaks ties so tests + UI stay stable across rebuilds.
    /// Excludes the input microbe from the result.
    public func related(toSlug slug: String, limit: Int = 3) -> [MicrobeCharacter] {
        let dependents = graph.dependents(for: slug)
        let sortedSlugs = dependents
            .map(\.id)
            .filter { $0 != slug }
            .sorted()
        return sortedSlugs
            .prefix(limit)
            .compactMap { microbesBySlug[$0] }
    }

    /// Convenience: returns up to `limit` related microbes for a character.
    public func related(to microbe: MicrobeCharacter, limit: Int = 3) -> [MicrobeCharacter] {
        related(toSlug: microbe.slug, limit: limit)
    }

    /// Returns the underlying graph for callers that need the full
    /// `ForgeKnowledgeGraph` API surface (e.g., gap analysis in Phase 2+).
    public var underlying: KnowledgeGraph { graph }
}
