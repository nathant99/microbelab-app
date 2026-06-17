import Testing
import Foundation
import Models
@testable import Services

@Suite("HistoricalContextService (Phase 3 scaffold)")
@MainActor
struct HistoricalContextServiceTests {

    @Test("canonical catalog ships all four cards in methodology → vaccine → kid-scientist order")
    func canonicalCatalogOrder() {
        let service = HistoricalContextService()
        let figures = service.catalog.map(\.figure)
        #expect(figures == [.koch, .pasteur, .salk, .marshall])
    }

    @Test("canonical catalog ships every card as `.placeholder` (reviewer-blocked)")
    func canonicalCatalogAuthoringDefaultsToPlaceholder() {
        let service = HistoricalContextService()
        for record in service.catalog {
            #expect(record.authoring == .placeholder)
        }
    }

    @Test("every figure in the catalog is unique by case")
    func catalogUniqueFigures() {
        let service = HistoricalContextService()
        let uniqueFigures = Set(service.catalog.map(\.figure))
        #expect(uniqueFigures.count == service.catalog.count)
    }

    @Test("every card rides the disease-story-immune gate (single-gate per Phase 3 design)")
    func allCardsRideTheImmuneStoryGate() {
        for figure in HistoricalContextFigure.allCases {
            #expect(figure.gateID == "disease-story-immune")
        }
    }

    @Test("presentation: parent has not opted in — surfaces gatedBehindConsent regardless of progression")
    func presentationWithoutConsent() {
        let service = HistoricalContextService()
        let record = HistoricalContextCardRecord(
            figure: .marshall,
            authoring: .reviewerSignedOff
        )
        let p = service.presentation(for: record, gateOpen: true, parentConsented: false)
        guard case .gatedBehindConsent(let r) = p else {
            Issue.record("expected gatedBehindConsent, got \(p)")
            return
        }
        #expect(r.figure == .marshall)
    }

    @Test("presentation: parent opted in but gate locked — surfaces gatedBehindProgression")
    func presentationGateLocked() {
        let service = HistoricalContextService()
        let record = HistoricalContextCardRecord(
            figure: .koch,
            authoring: .reviewerSignedOff
        )
        let p = service.presentation(for: record, gateOpen: false, parentConsented: true)
        guard case .gatedBehindProgression = p else {
            Issue.record("expected gatedBehindProgression, got \(p)")
            return
        }
    }

    @Test("presentation: gate open + consent in + authoring placeholder — surfaces authoringPending")
    func presentationAuthoringPending() {
        let service = HistoricalContextService()
        let record = HistoricalContextCardRecord(
            figure: .pasteur,
            authoring: .placeholder
        )
        let p = service.presentation(for: record, gateOpen: true, parentConsented: true)
        guard case .authoringPending = p else {
            Issue.record("expected authoringPending for .placeholder authoring, got \(p)")
            return
        }
    }

    @Test("presentation: draftAwaitingReview is treated the same as placeholder — kids never see un-signed-off prose")
    func draftAwaitingReviewBehavesAsPlaceholder() {
        let service = HistoricalContextService()
        let record = HistoricalContextCardRecord(
            figure: .salk,
            authoring: .draftAwaitingReview
        )
        let p = service.presentation(for: record, gateOpen: true, parentConsented: true)
        guard case .authoringPending = p else {
            Issue.record("expected authoringPending for .draftAwaitingReview authoring, got \(p)")
            return
        }
    }

    @Test("presentation: reviewerSignedOff + gate open + consent in — surfaces ready")
    func presentationReady() {
        let service = HistoricalContextService()
        let record = HistoricalContextCardRecord(
            figure: .marshall,
            authoring: .reviewerSignedOff
        )
        let p = service.presentation(for: record, gateOpen: true, parentConsented: true)
        guard case .ready(let r) = p else {
            Issue.record("expected ready, got \(p)")
            return
        }
        #expect(r.figure == .marshall)
    }

    @Test("record(for:) returns the catalog entry for a known figure")
    func recordForKnownFigure() {
        let service = HistoricalContextService()
        let record = service.record(for: .marshall)
        #expect(record?.figure == .marshall)
    }

    @Test("trauma-informed register: display titles + eras + contributions avoid hero-myth / mortality / dramatic lexicon")
    func metadataTraumaSafeRegister() {
        // Anti-credentialism per CQ CONTENT_STYLE_GUIDE.md § 4.5: titles
        // stay on the figure's name (no "the great X" / "the genius
        // who..."); contributions stay on the curricular hook (no "saved
        // millions" / "world's most..." / "miracle" framing). Trauma-
        // informed per .claude/rules/trauma-informed-content.md: mortality-
        // counting + drama-cult is forbidden — historical drama is real
        // but the register frames it as patient observation NOT heroism.
        let stoplist = [
            // Hero-myth lexicon
            "great", "genius", "miracle", "hero", "amazing", "legend",
            // Mortality + dramatic framing
            "saved millions", "killed millions", "died from", "horror",
            "tragedy", "doom",
            // Warfare
            "war ", "battle", "weapon", "fight"
        ]
        for figure in HistoricalContextFigure.allCases {
            let blob = (figure.displayTitle + " " + figure.era + " " + figure.contribution).lowercased()
            for token in stoplist {
                #expect(!blob.contains(token),
                        "Figure \(figure) metadata contains stoplist token '\(token)': '\(blob)'")
            }
        }
    }

    @Test("Marshall's relevantMicrobeSlugs surfaces the Phase 2 Pylo cast bridge")
    func marshallSurfacesH_pyloriBridge() {
        // Load-bearing per .claude/rules/distributed-narrative.md § Cluster
        // coherence — historical context cards must surface their bridges
        // to bundled cast members so the cross-curricular link is visible
        // to consuming views. Marshall ↔ Pylo (PR #119 Phase 2 cast
        // expansion).
        #expect(HistoricalContextFigure.marshall.relevantMicrobeSlugs.contains("pylo"))
    }

    @Test("relevantMicrobeSlugs values are all lowercase kebab-case (catalog convention)")
    func relevantMicrobeSlugsLowercaseConvention() {
        for figure in HistoricalContextFigure.allCases {
            for slug in figure.relevantMicrobeSlugs {
                #expect(!slug.isEmpty)
                #expect(slug.lowercased() == slug,
                        "Slug '\(slug)' on \(figure) must be lowercase to match catalog convention")
            }
        }
    }

    @Test("crossPortfolioBridges values are all lowercase portfolio app slugs")
    func crossPortfolioBridgesLowercaseConvention() {
        for figure in HistoricalContextFigure.allCases {
            for slug in figure.crossPortfolioBridges {
                #expect(!slug.isEmpty)
                #expect(slug.lowercased() == slug,
                        "Cross-portfolio bridge '\(slug)' on \(figure) must be lowercase to match portfolio slug convention")
            }
        }
    }

    @Test("codable roundtrip preserves figure + authoring on the record")
    func codableRoundtripPreservesRecord() throws {
        let original = HistoricalContextCardRecord(
            figure: .pasteur,
            authoring: .draftAwaitingReview
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            HistoricalContextCardRecord.self,
            from: data
        )
        #expect(decoded == original)
    }
}
