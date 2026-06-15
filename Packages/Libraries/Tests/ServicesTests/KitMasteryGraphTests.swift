import Foundation
import Testing
@testable import Services

@Suite("KitMasteryGraph")
nonisolated struct KitMasteryGraphTests {
    @Test func canonicalKitSlugsMatchAllShippedKits() {
        // Pin against the canonical Phase 1 + Phase 2 kit slug order so
        // adding a kit without registering its prerequisite edges fails
        // loudly in CI. Mirror of QuestionKitService.allKitSlugs but kept
        // in Services because Services is where the graph lives.
        #expect(KitMasteryGraph.canonicalKitSlugs == [
            "microbiology-basics",
            "microbiome",
            "immune-defense",
            "beneficial-microbes",
            "adaptive-immunity",
            "oral-microbiome",
            "skin-microbiome",
            "soil-microbiome"
        ])
    }

    @Test func graphHasNoCyclesOrOrphans() {
        let graph = KitMasteryGraph()
        let result = graph.validate()
        // No cycles, no missing nodes, no orphans (every kit either
        // depends on another OR is depended on by another).
        #expect(result.issues.isEmpty,
                "KitMasteryGraph must be acyclic + fully connected; issues: \(result.issues)")
    }

    @Test func rootKitHasNoPrerequisites() {
        let graph = KitMasteryGraph()
        #expect(graph.prerequisites(for: "microbiology-basics").isEmpty,
                "kit_01 microbiology-basics is the canonical root + must have no prerequisites")
    }

    @Test func microbiomeUnlocksMultipleKits() {
        let graph = KitMasteryGraph()
        let unlocks = Set(graph.unlocks(after: "microbiome"))
        // Completing microbiome unlocks beneficial-microbes (Phase 1) +
        // oral / skin / soil microbiome (Phase 2).
        #expect(unlocks.contains("beneficial-microbes"))
        #expect(unlocks.contains("oral-microbiome"))
        #expect(unlocks.contains("skin-microbiome"))
        #expect(unlocks.contains("soil-microbiome"))
        #expect(unlocks.count == 4)
    }

    @Test func immuneDefenseUnlocksAdaptiveImmunity() {
        let graph = KitMasteryGraph()
        let unlocks = graph.unlocks(after: "immune-defense")
        #expect(unlocks == ["adaptive-immunity"])
    }

    @Test func ecologyKitsRequireMicrobiomeCompleted() {
        let graph = KitMasteryGraph()
        for ecologyKit in ["oral-microbiome", "skin-microbiome", "soil-microbiome"] {
            #expect(graph.prerequisites(for: ecologyKit) == ["microbiome"],
                    "Ecology kit \(ecologyKit) must require kit 02 (microbiome) per canonical chain")
        }
    }

    @Test func nextAvailableForEmptyCompletedSetReturnsRoot() {
        let graph = KitMasteryGraph()
        let available = graph.nextAvailable(completedKitSlugs: [])
        #expect(available == ["microbiology-basics"],
                "With no kits completed only the root kit is available")
    }

    @Test func nextAvailableAfterBasicsReturnsKits2And3() {
        let graph = KitMasteryGraph()
        let available = Set(
            graph.nextAvailable(completedKitSlugs: ["microbiology-basics"])
        )
        #expect(available == ["microbiome", "immune-defense"],
                "Completing kit 01 unlocks both microbiome (02) + immune-defense (03)")
    }

    @Test func nextAvailableAfterMicrobiomeFamilyReturnsEcologies() {
        let graph = KitMasteryGraph()
        let completed: Set<String> = ["microbiology-basics", "microbiome"]
        let available = Set(graph.nextAvailable(completedKitSlugs: completed))
        // immune-defense was already available from kit 01; beneficial /
        // oral / skin / soil all unlock when microbiome lands.
        #expect(available.contains("immune-defense"))
        #expect(available.contains("beneficial-microbes"))
        #expect(available.contains("oral-microbiome"))
        #expect(available.contains("skin-microbiome"))
        #expect(available.contains("soil-microbiome"))
        // Adaptive immunity still gated on immune-defense.
        #expect(!available.contains("adaptive-immunity"))
    }

    @Test func nextRecommendedKitReturnsFirstByCanonicalOrder() {
        let graph = KitMasteryGraph()
        #expect(graph.nextRecommendedKit(completedKitSlugs: []) == "microbiology-basics")
        #expect(graph.nextRecommendedKit(completedKitSlugs: ["microbiology-basics"]) == "microbiome",
                "After kit 01, canonical-order recommendation is kit 02 (microbiome) over kit 03")
    }

    @Test func nextRecommendedKitIsNilWhenAllCompleted() {
        let graph = KitMasteryGraph()
        let allCompleted = Set(KitMasteryGraph.canonicalKitSlugs)
        #expect(graph.nextRecommendedKit(completedKitSlugs: allCompleted) == nil,
                "All kits completed → no recommendation")
    }

    @Test func kitCountAndEdgeCountInvariants() {
        let graph = KitMasteryGraph()
        // 8 kits + 7 prerequisite edges (one per dependency arrow). Future
        // edits adding kits or edges should trip these invariants.
        #expect(graph.kitCount == 8)
        #expect(graph.edgeCount == 7)
    }
}
