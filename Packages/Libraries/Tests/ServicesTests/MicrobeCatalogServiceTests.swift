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
            #expect(service.microbes.count == 12)
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

    @Test func beneficialMicrobesFlaggedCorrectly() throws {
        guard case .success(let service) = MicrobeCatalogService.loadBundled() else {
            Issue.record("Catalog should have loaded")
            return
        }
        let beneficial = service.microbes(role: .beneficial)
        // Per CLAUDE.md trauma-informed posture: beneficial microbes are foregrounded.
        #expect(beneficial.count >= 4, "Beneficial-microbe foregrounding requires ≥4 beneficial cast members.")
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
