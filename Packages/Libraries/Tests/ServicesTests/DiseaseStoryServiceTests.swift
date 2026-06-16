import Testing
import Foundation
import Models
@testable import Services

@Suite("DiseaseStoryService (Phase 3 scaffold)")
@MainActor
struct DiseaseStoryServiceTests {

    @Test("canonical catalog ships all four arcs in gentlest-first order")
    func canonicalCatalogOrder() {
        let service = DiseaseStoryService()
        let arcs = service.catalog.map(\.arc)
        #expect(arcs == [.handwashing, .vaccinePriming, .antibioticStewardship, .outbreakRecovery])
    }

    @Test("canonical catalog ships every arc as `.placeholder` (reviewer-blocked)")
    func canonicalCatalogAuthoringDefaultsToPlaceholder() {
        let service = DiseaseStoryService()
        for record in service.catalog {
            #expect(record.authoring == .placeholder)
        }
    }

    @Test("every arc in the catalog is unique by case")
    func catalogUniqueArcs() {
        let service = DiseaseStoryService()
        let uniqueArcs = Set(service.catalog.map(\.arc))
        #expect(uniqueArcs.count == service.catalog.count)
    }

    @Test("vaccinePriming rides the immune gate; other three ride the microbiome gate")
    func gateRoutingByArc() {
        #expect(DiseaseStoryArc.vaccinePriming.gateID == "disease-story-immune")
        #expect(DiseaseStoryArc.handwashing.gateID == "disease-story-microbiome")
        #expect(DiseaseStoryArc.antibioticStewardship.gateID == "disease-story-microbiome")
        #expect(DiseaseStoryArc.outbreakRecovery.gateID == "disease-story-microbiome")
    }

    @Test("presentation: parent has not opted in — every arc gates behind consent first, regardless of progression")
    func presentationWithoutConsent() {
        let service = DiseaseStoryService()
        let record = DiseaseStoryArcRecord(arc: .handwashing, authoring: .reviewerSignedOff)
        let p = service.presentation(for: record, gateOpen: true, parentConsented: false)
        guard case .gatedBehindConsent(let r) = p else {
            Issue.record("expected gatedBehindConsent, got \(p)")
            return
        }
        #expect(r.arc == .handwashing)
    }

    @Test("presentation: parent opted in but gate still locked — surfaces gatedBehindProgression")
    func presentationGateLocked() {
        let service = DiseaseStoryService()
        let record = DiseaseStoryArcRecord(arc: .handwashing, authoring: .reviewerSignedOff)
        let p = service.presentation(for: record, gateOpen: false, parentConsented: true)
        guard case .gatedBehindProgression = p else {
            Issue.record("expected gatedBehindProgression, got \(p)")
            return
        }
    }

    @Test("presentation: gate open + consent in + authoring placeholder — surfaces authoringPending")
    func presentationAuthoringPending() {
        let service = DiseaseStoryService()
        let record = DiseaseStoryArcRecord(arc: .handwashing, authoring: .placeholder)
        let p = service.presentation(for: record, gateOpen: true, parentConsented: true)
        guard case .authoringPending = p else {
            Issue.record("expected authoringPending for .placeholder authoring, got \(p)")
            return
        }
    }

    @Test("presentation: draftAwaitingReview is treated the same as placeholder — kids never see un-signed-off prose")
    func draftAwaitingReviewBehavesAsPlaceholder() {
        let service = DiseaseStoryService()
        let record = DiseaseStoryArcRecord(arc: .vaccinePriming, authoring: .draftAwaitingReview)
        let p = service.presentation(for: record, gateOpen: true, parentConsented: true)
        guard case .authoringPending = p else {
            Issue.record("expected authoringPending for .draftAwaitingReview authoring, got \(p)")
            return
        }
    }

    @Test("presentation: reviewerSignedOff + gate open + consent in — surfaces ready")
    func presentationReady() {
        let service = DiseaseStoryService()
        let record = DiseaseStoryArcRecord(arc: .vaccinePriming, authoring: .reviewerSignedOff)
        let p = service.presentation(for: record, gateOpen: true, parentConsented: true)
        guard case .ready(let r) = p else {
            Issue.record("expected ready, got \(p)")
            return
        }
        #expect(r.arc == .vaccinePriming)
    }

    @Test("record(for:) returns the catalog entry for a known arc")
    func recordForKnownArc() {
        let service = DiseaseStoryService()
        let record = service.record(for: .vaccinePriming)
        #expect(record?.arc == .vaccinePriming)
    }

    @Test("trauma-informed register: display titles avoid weapons / war / fear vocabulary")
    func displayTitlesTraumaSafeRegister() {
        let stoplist = ["fight", "attack", "war", "battle", "weapon", "kill", "destroy", "enemy", "germ", "scary", "fear"]
        for arc in DiseaseStoryArc.allCases {
            let title = arc.displayTitle.lowercased()
            for token in stoplist {
                #expect(!title.contains(token),
                        "Display title for \(arc) contains stoplist token \(token): \"\(title)\"")
            }
        }
    }

    @Test("trauma-informed register: primitive descriptions avoid weapons / war / fear vocabulary")
    func primitiveDescriptionsTraumaSafeRegister() {
        let stoplist = ["fight", "attack", "war", "battle", "weapon", "kill", "destroy", "enemy", "scary"]
        for arc in DiseaseStoryArc.allCases {
            let primitive = arc.primitive.lowercased()
            for token in stoplist {
                #expect(!primitive.contains(token),
                        "Primitive for \(arc) contains stoplist token \(token): \"\(primitive)\"")
            }
        }
    }
}
