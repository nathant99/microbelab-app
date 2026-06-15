import Foundation
import Models
import ForgeKnowledgeGraph
import ForgeModels

/// Question-kit prerequisite graph derived from the bundled kits. Wraps
/// `ForgeKnowledgeGraph.KnowledgeGraph` whose nodes are kits (keyed by
/// slug) and whose edges encode the canonical kit-progression chain:
///
/// ```
///                    kit_01 (basics)
///                    /            \
///            kit_02 (microbiome)   kit_03 (immune)
///            /      |      \            |
///   kit_04   kit_06  kit_07  kit_08    kit_05 (adaptive)
///   (beneficial)  (oral) (skin) (soil)
/// ```
///
/// Per `.claude/rules/forgekit.md` § ForgeMasteryEngine SHIPPED 1.0.0-rc.2
/// the canonical mastery-graph type lives in `ForgeMasteryEngine.MasteryGraph`.
/// MicrobeLab's current ForgeKit pin (`from: "0.99.0"`) doesn't yet include
/// that module — `ForgeMasteryEngine` ships in 1.0.0-rc.2 with breaking
/// changes to `AvatarAssetCatalog` that require a separate cascade-fix
/// round to clear. This wrapper uses the already-pinned
/// `ForgeKnowledgeGraph.KnowledgeGraph` (which carries prerequisite-edge
/// semantics via `EdgeStrength.required`) to deliver the same pedagogical
/// surface — a kid finishing kit 01 unlocks kits 02 + 03; finishing kit 02
/// unlocks kits 04/06/07/08; finishing kit 03 unlocks kit 05.
///
/// When the ForgeKit pin bumps to 1.0.0-rc.2+ in a focused round, the
/// wrapper migrates to `ForgeMasteryEngine.MasteryGraph<String>` + gains
/// the FSRS-6 retention + `TopicMasteryState.isRacingAhead` / `isStuck`
/// derivations that the canonical surface offers.
///
/// Pure value type per `.claude/rules/concurrency.md` — `nonisolated` so
/// the Progress / Codex UI (MainActor) + tests can use it without a hop.
public nonisolated struct KitMasteryGraph: Sendable {
    private let graph: KnowledgeGraph
    /// Canonical kit slugs in the order they're bundled. Mirror of
    /// `QuestionKitService.allKitSlugs` so the graph stays in sync.
    public static let canonicalKitSlugs: [String] = [
        "microbiology-basics",   // kit 01 (root)
        "microbiome",            // kit 02
        "immune-defense",        // kit 03
        "beneficial-microbes",   // kit 04 ← kit 02
        "adaptive-immunity",     // kit 05 ← kit 03
        "oral-microbiome",       // kit 06 ← kit 02
        "skin-microbiome",       // kit 07 ← kit 02
        "soil-microbiome"        // kit 08 ← kit 02
    ]

    /// Canonical prerequisite edges. `.required` strength so
    /// `ForgeKnowledgeGraph.prerequisites(for:strength: .required)` returns
    /// the gate-bearing parent kits.
    public static let canonicalEdges: [(from: String, to: String)] = [
        ("microbiology-basics", "microbiome"),
        ("microbiology-basics", "immune-defense"),
        ("microbiome", "beneficial-microbes"),
        ("immune-defense", "adaptive-immunity"),
        ("microbiome", "oral-microbiome"),
        ("microbiome", "skin-microbiome"),
        ("microbiome", "soil-microbiome")
    ]

    public init() {
        var nodes = [KnowledgeNode]()
        nodes.reserveCapacity(Self.canonicalKitSlugs.count)
        for (index, slug) in Self.canonicalKitSlugs.enumerated() {
            nodes.append(
                KnowledgeNode(
                    id: slug,
                    title: slug.replacingOccurrences(of: "-", with: " ").capitalized,
                    bloomLevel: Self.bloomLevel(for: index),
                    topic: "microbiology",
                    subtopic: nil,
                    gradeBand: "MS",
                    standards: [],
                    contentKitIDs: [slug]
                )
            )
        }
        let edges = Self.canonicalEdges.map {
            KnowledgeEdge(from: $0.from, to: $0.to, strength: .required)
        }
        self.graph = KnowledgeGraph(nodes: nodes, edges: edges)
    }

    /// Bloom-level proxy — kit 01 is `.remember` (recall basics), kits 02-03
    /// `.understand` (mechanism), kits 04-05 `.apply` (cross-microbe + memory
    /// recall in context), kits 06-08 `.analyze` (per-ecology cohort
    /// comparison). Used by ForgeReporting / ProgressView to surface the
    /// kid's mastery distribution across cognitive levels.
    private static func bloomLevel(for index: Int) -> BloomLevel {
        switch index {
        case 0: return .remember
        case 1, 2: return .understand
        case 3, 4: return .apply
        default: return .analyze
        }
    }

    /// Slugs of kits the kid must complete BEFORE the given kit unlocks.
    /// Empty array for root kits (kit 01).
    public func prerequisites(for slug: String) -> [String] {
        graph.prerequisites(for: slug, strength: .required).map(\.id)
    }

    /// Slugs of kits the given kit unlocks. Empty array for leaf kits
    /// (kits 04 / 05 / 06 / 07 / 08).
    public func unlocks(after slug: String) -> [String] {
        graph.dependents(for: slug).map(\.id)
    }

    /// Slugs of every kit the kid can attempt NOW given the set of kits they've
    /// completed. A kit is unlocked iff all its prerequisites are in the
    /// completed set OR it's a root kit (no prerequisites). The kid's
    /// currently-completed kits are excluded so this returns "next to try"
    /// candidates, ordered by canonical kit order.
    public func nextAvailable(completedKitSlugs: Set<String>) -> [String] {
        Self.canonicalKitSlugs.filter { slug in
            guard !completedKitSlugs.contains(slug) else { return false }
            let prereqs = prerequisites(for: slug)
            return prereqs.allSatisfy(completedKitSlugs.contains)
        }
    }

    /// One-step recommendation: the FIRST available kit per canonical kit
    /// order. UI consumers (Progress tab "Up next") use this for a single
    /// strong recommendation rather than presenting all candidates.
    public func nextRecommendedKit(completedKitSlugs: Set<String>) -> String? {
        nextAvailable(completedKitSlugs: completedKitSlugs).first
    }

    /// Total kit count — pinned in tests so adding a kit to
    /// `canonicalKitSlugs` without adding the prerequisite edges surfaces
    /// immediately.
    public var kitCount: Int { graph.nodeCount }

    /// Total prerequisite edge count.
    public var edgeCount: Int { graph.edgeCount }

    /// Validation pass — surfaces missing nodes / cycles / orphans. Used by
    /// the unit-test architecture invariant; if a future edit introduces a
    /// cycle (e.g., "kit 06 requires kit 04" while kit 04 already requires
    /// kit 02), this fires.
    public func validate() -> GraphValidationResult {
        graph.validate()
    }
}
