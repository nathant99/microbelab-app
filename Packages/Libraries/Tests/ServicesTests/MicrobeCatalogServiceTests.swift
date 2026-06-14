import Foundation
import Testing
@testable import Services
@testable import Models

@Suite("MicrobeCatalogService")
nonisolated struct MicrobeCatalogServiceTests {
    @Test func bundledCatalogLoads() throws {
        let result = MicrobeCatalogService.loadBundled()
        switch result {
        case .failure(let error):
            Issue.record("Bundled catalog should load but errored: \(error)")
        case .success(let service):
            // Phase 2 expansion: 12 → 20 (8 added covering skin / soil / stomach
            // / oralCavity ecology gaps). See microbes.json notes.
            #expect(service.microbes.count == 20)
        }
    }

    @Test func canonicalDNCastIsPresent() throws {
        guard case .success(let service) = MicrobeCatalogService.loadBundled() else {
            Issue.record("Catalog should have loaded")
            return
        }
        // 6 canonical DN cast per HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT
        let canonical = ["lacto", "yeast", "photo", "net", "spore", "guard"]
        for slug in canonical {
            #expect(service.microbe(forSlug: slug) != nil, "Missing canonical DN cast slug: \(slug)")
        }
    }

    @Test func phase2CastExpansionPresent() throws {
        guard case .success(let service) = MicrobeCatalogService.loadBundled() else {
            Issue.record("Catalog should have loaded")
            return
        }
        // Phase 2 cast expansion (8 microbes closing the FEATURE_PLAN checkbox).
        let phase2 = ["sebu", "demi", "halo", "pylo", "sweet", "nodu", "therm", "loam"]
        for slug in phase2 {
            #expect(service.microbe(forSlug: slug) != nil,
                    "Missing Phase 2 expansion slug: \(slug)")
        }
    }

    @Test func phase2EcologyCoverageExpanded() throws {
        guard case .success(let service) = MicrobeCatalogService.loadBundled() else {
            Issue.record("Catalog should have loaded")
            return
        }
        // Phase 2 microbiome scenes (oral / skin / soil / stomach) need at least
        // 2-3 microbes per ecology to be playable. Pin per-slot floors so a future
        // edit doesn't silently regress the Phase 2 prerequisite.
        let skin = service.microbes.filter { $0.preferredEnvironment == .skin }
        let soil = service.microbes.filter { $0.preferredEnvironment == .soil }
        let oral = service.microbes.filter { $0.preferredEnvironment == .oralCavity }
        let stomach = service.microbes.filter { $0.preferredEnvironment == .stomach }
        #expect(skin.count >= 3, "Skin ecology needs ≥3 microbes for Phase 2 scene")
        #expect(soil.count >= 6, "Soil ecology needs ≥6 microbes for Phase 2 scene")
        #expect(oral.count >= 3, "Oral ecology needs ≥3 microbes for Phase 2 scene")
        #expect(stomach.count >= 1, "Stomach ecology needs ≥1 microbe (H. pylori bridge)")
    }

    @Test func beneficialMicrobesFlaggedCorrectly() throws {
        guard case .success(let service) = MicrobeCatalogService.loadBundled() else {
            Issue.record("Catalog should have loaded")
            return
        }
        let beneficial = service.microbes(role: .beneficial)
        // Per CLAUDE.md trauma-informed posture: beneficial microbes are
        // foregrounded. Post Phase-2 expansion the floor rises to ≥ 10 (≥ 50%
        // of the 20-microbe catalog), preserving the beneficial-first ratio.
        #expect(beneficial.count >= 10,
                "Beneficial-microbe foregrounding requires ≥10 beneficial cast members at 20-microbe scale.")
        let pathogens = service.microbes(role: .pathogenic)
        #expect(pathogens.isEmpty,
                "Phase 2 expansion preserves the no-pathogenic-cast trauma-informed posture.")
    }

    @Test func uniqueSlugs() throws {
        guard case .success(let service) = MicrobeCatalogService.loadBundled() else {
            Issue.record("Catalog should have loaded")
            return
        }
        let slugs = service.microbes.map(\.slug)
        #expect(Set(slugs).count == slugs.count, "Slugs must be unique")
    }

    @Test func everyMicrobeHasVoiceLines() throws {
        guard case .success(let service) = MicrobeCatalogService.loadBundled() else {
            Issue.record("Catalog should have loaded")
            return
        }
        for microbe in service.microbes {
            // Each character ships 3-5 in-character lines per the DN-S voice
            // register card.
            #expect(microbe.voiceLines.count >= 2,
                    "\(microbe.slug) must ship at least 2 voice lines")
            for line in microbe.voiceLines {
                #expect(!line.isEmpty,
                        "\(microbe.slug) voice line must not be empty")
            }
        }
    }
}
