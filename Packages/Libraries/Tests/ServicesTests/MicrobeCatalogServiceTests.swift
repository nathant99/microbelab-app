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
            // Phase 4 extremophile pack: 20 → 24 (4 added bridging the
            // global-microbiome tour — Crenarch / Acido / Cryo / Baro).
            // See microbes.json notes.
            #expect(service.microbes.count == 24)
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

    @Test func phase4ExtremophilePackPresent() throws {
        guard case .success(let service) = MicrobeCatalogService.loadBundled() else {
            Issue.record("Catalog should have loaded")
            return
        }
        // Phase 4 extremophile pack (4 microbes closing the FEATURE_PLAN
        // checkbox). Bridges to the global-microbiome tour (Yellowstone /
        // deep-sea / glacial ice / acidic mine drainage).
        let phase4 = ["crenarch", "acido", "cryo", "baro"]
        for slug in phase4 {
            #expect(service.microbe(forSlug: slug) != nil,
                    "Missing Phase 4 extremophile slug: \(slug)")
        }
    }

    @Test func phase4ExtremophilesTraumaSafeRegister() throws {
        guard case .success(let service) = MicrobeCatalogService.loadBundled() else {
            Issue.record("Catalog should have loaded")
            return
        }
        // Extremophile cast members ship the wonder-and-adaptation framing per
        // the trauma-informed posture: never threat / never struggle / never
        // doom. Pinned by a stoplist applied to catchphrase + factCard +
        // voiceLines for the 4 Phase 4 entries.
        let stoplist = ["scary", "dangerous", "deadly", "kill", "horror",
                        "doom", "suffer", "violent", "attack"]
        let phase4Slugs: Set<String> = ["crenarch", "acido", "cryo", "baro"]
        for microbe in service.microbes where phase4Slugs.contains(microbe.slug) {
            let combined = (microbe.catchphrase + " " + microbe.factCard + " "
                            + microbe.voiceLines.joined(separator: " ")).lowercased()
            for word in stoplist {
                #expect(!combined.contains(word),
                        "Phase 4 extremophile '\(microbe.slug)' must not surface '\(word)' (trauma-safe register).")
            }
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
        // foregrounded. Post Phase-4 expansion the absolute floor stays at
        // ≥ 10 (the 4 extremophiles all ship as neutral, not beneficial — they
        // demonstrate adaptation, not symbiosis). Beneficial-first ratio drops
        // to ~46% at the 24-microbe scale but the absolute beneficial count
        // remains ≥ 10 which is the load-bearing trauma-informed invariant.
        #expect(beneficial.count >= 10,
                "Beneficial-microbe foregrounding requires ≥10 beneficial cast members at 24-microbe scale.")
        let pathogens = service.microbes(role: .pathogenic)
        #expect(pathogens.isEmpty,
                "Phase 4 expansion preserves the no-pathogenic-cast trauma-informed posture.")
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
