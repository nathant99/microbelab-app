import Foundation
import Models
import ForgeKnowledgeGraph
import ForgeModels

/// Cross-microbe ecology graph derived from the bundled `MicrobeCatalog`.
/// Wraps a `ForgeKnowledgeGraph.KnowledgeGraph` whose nodes are microbes
/// (keyed by `slug`) and whose edges encode three cross-microbe relations:
///
/// 1. **shared-habitat** (`.recommended` strength) — microbes whose
///    `preferredEnvironment` (`GutSlot`) is the same literally rub
///    elbows in the kid's body. v1 baseline; emitted symmetrically.
/// 2. **same-role cohort** (`.related` strength) — microbes whose
///    `role` (`MicrobeRole`) is the same form a cohort kids can
///    traverse for "show me other beneficial microbes" suggestions.
/// 3. **same-kingdom cohort** (`.related` strength) — microbes whose
///    `kingdom` (`MicrobeKingdom`) is the same form a cohort for
///    "show me other bacteria" suggestions. Curriculum-aligned with
///    NGSS MS-LS1-1 taxonomy.
///
/// Pure value type per `.claude/rules/concurrency.md` — `nonisolated` so the
/// codex grid (MainActor) and tests (any isolation) can use it without an
/// isolation hop.
///
/// All three edge classes are emitted at `EdgeStrength.recommended`
/// (the only kid-pedagogy-grade strength on `ForgeKnowledgeGraph` —
/// `.required` is reserved for prerequisite locks). The per-class
/// distinction lives at the wrapper layer: `related(toSlug:)` returns
/// shared-habitat neighbors only; `relatedByRole(toSlug:)` /
/// `relatedByKingdom(toSlug:)` return the role / kingdom cohorts;
/// `allRelated(toSlug:)` returns the deduplicated union.
///
/// **Why not richer cross-feeding edges**: per `.claude/rules/ai-content.md`
/// we don't generate ecology from the AI mentor — derivation is from the
/// authored catalog only. The Phase 1 catalog doesn't carry explicit
/// cross-feeding relationships, so habitat / role / kingdom co-occurrence
/// are the strongest signals we can derive without making up biology that
/// isn't on the curriculum.
public nonisolated struct MicrobeKnowledgeGraph: Sendable {
    private let graph: KnowledgeGraph
    private let microbesBySlug: [String: MicrobeCharacter]

    /// Builds the graph from a catalog. All three edge classes are emitted
    /// symmetrically (i.e., `from: lacto → to: bifido` AND
    /// `from: bifido → to: lacto`) so traversal is symmetric across every
    /// dimension.
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
        // 1. Shared-habitat edges (symmetric, `.recommended` strength).
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
        // 2. Same-role cohort edges (symmetric, `.related` strength).
        let byRole = Dictionary(grouping: microbes) { $0.role }
        for (_, cohort) in byRole where cohort.count >= 2 {
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
        // 3. Same-kingdom cohort edges (symmetric, `.related` strength).
        let byKingdom = Dictionary(grouping: microbes) { $0.kingdom }
        for (_, cohort) in byKingdom where cohort.count >= 2 {
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

    /// Total directed edge count — sum across all three edge classes.
    public var edgeCount: Int { graph.edgeCount }

    /// Returns up to `limit` microbe characters related to `slug` via the
    /// shared-habitat graph. Determinism-by-slug: alphabetic ordering on
    /// the slug breaks ties so tests + UI stay stable across rebuilds.
    /// Excludes the input microbe from the result.
    ///
    /// Backward-compatible: the v1 behavior is preserved. Callers wanting
    /// role / kingdom cohorts use `relatedByRole(toSlug:)` /
    /// `relatedByKingdom(toSlug:)` / `allRelated(toSlug:)`.
    public func related(toSlug slug: String, limit: Int = 3) -> [MicrobeCharacter] {
        guard let microbe = microbesBySlug[slug] else { return [] }
        return microbesBySlug.values
            .filter { $0.preferredEnvironment == microbe.preferredEnvironment && $0.slug != slug }
            .sorted { $0.slug < $1.slug }
            .prefix(limit)
            .map { $0 }
    }

    /// Convenience: returns up to `limit` related microbes for a character.
    public func related(to microbe: MicrobeCharacter, limit: Int = 3) -> [MicrobeCharacter] {
        related(toSlug: microbe.slug, limit: limit)
    }

    /// Returns up to `limit` microbe characters in the same `MicrobeRole`
    /// cohort. Alphabetic-by-slug deterministic ordering. Excludes self.
    public func relatedByRole(toSlug slug: String, limit: Int = 3) -> [MicrobeCharacter] {
        guard let microbe = microbesBySlug[slug] else { return [] }
        return microbesBySlug.values
            .filter { $0.role == microbe.role && $0.slug != slug }
            .sorted { $0.slug < $1.slug }
            .prefix(limit)
            .map { $0 }
    }

    /// Convenience: same-role cohort for a character.
    public func relatedByRole(to microbe: MicrobeCharacter, limit: Int = 3) -> [MicrobeCharacter] {
        relatedByRole(toSlug: microbe.slug, limit: limit)
    }

    /// Returns up to `limit` microbe characters in the same `MicrobeKingdom`
    /// cohort. Alphabetic-by-slug deterministic ordering. Excludes self.
    public func relatedByKingdom(toSlug slug: String, limit: Int = 3) -> [MicrobeCharacter] {
        guard let microbe = microbesBySlug[slug] else { return [] }
        return microbesBySlug.values
            .filter { $0.kingdom == microbe.kingdom && $0.slug != slug }
            .sorted { $0.slug < $1.slug }
            .prefix(limit)
            .map { $0 }
    }

    /// Convenience: same-kingdom cohort for a character.
    public func relatedByKingdom(to microbe: MicrobeCharacter, limit: Int = 3) -> [MicrobeCharacter] {
        relatedByKingdom(toSlug: microbe.slug, limit: limit)
    }

    /// Returns up to `limit` microbe characters related to `slug` via any
    /// of the three edge classes (shared-habitat / same-role / same-kingdom).
    /// Deduplicated by slug; alphabetic-by-slug ordering so the result is
    /// deterministic for tests + UI.
    public func allRelated(toSlug slug: String, limit: Int = 6) -> [MicrobeCharacter] {
        guard let microbe = microbesBySlug[slug] else { return [] }
        let unionSlugs = Set(microbesBySlug.values
            .filter { other in
                other.slug != slug && (
                    other.preferredEnvironment == microbe.preferredEnvironment ||
                    other.role == microbe.role ||
                    other.kingdom == microbe.kingdom
                )
            }
            .map(\.slug))
        return unionSlugs
            .sorted()
            .prefix(limit)
            .compactMap { microbesBySlug[$0] }
    }

    /// Convenience: union cohort for a character.
    public func allRelated(to microbe: MicrobeCharacter, limit: Int = 6) -> [MicrobeCharacter] {
        allRelated(toSlug: microbe.slug, limit: limit)
    }

    /// Returns the underlying graph for callers that need the full
    /// `ForgeKnowledgeGraph` API surface (e.g., gap analysis in Phase 2+).
    public var underlying: KnowledgeGraph { graph }
}
