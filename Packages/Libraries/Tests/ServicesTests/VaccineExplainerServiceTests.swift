import Foundation
import Testing
@testable import Models
@testable import Services

@MainActor
@Suite("VaccineExplainerService")
final class VaccineExplainerServiceTests {
    nonisolated deinit {}

    @Test func canonicalCatalogShipsFourPlaceholderSteps() {
        let catalog = VaccineExplainerService.canonicalCatalog()
        #expect(catalog.count == 4)
        for record in catalog {
            #expect(record.authoring == .placeholder)
        }
    }

    @Test func canonicalCatalogOrderIsGentlestFirst() {
        // Load-bearing: the kid's first exposure must lead with
        // introduction, not booster rationale.
        let order = VaccineExplainerService.canonicalCatalog().map(\.step)
        #expect(order == [
            .introduction,
            .antibodyPriming,
            .memoryFormation,
            .boosterRationale
        ])
    }

    @Test func explainerGateIDRidesDiseaseStoryImmune() {
        // The explainer shares the gate with the vaccinePriming
        // disease-story arc so the kid reaches both at the same boundary.
        #expect(VaccineExplainerService.explainerGateID == "disease-story-immune")
    }

    @Test func presentationGatedBehindConsentWhenParentNotOptedIn() {
        let service = VaccineExplainerService()
        for record in service.catalog {
            let presentation = service.presentation(
                for: record,
                gateOpen: true,
                parentConsented: false
            )
            guard case .gatedBehindConsent = presentation else {
                Issue.record("Expected gatedBehindConsent for \(record.step) when parent has not opted in.")
                continue
            }
        }
    }

    @Test func presentationGatedBehindProgressionWhenGateClosed() {
        let service = VaccineExplainerService()
        for record in service.catalog {
            let presentation = service.presentation(
                for: record,
                gateOpen: false,
                parentConsented: true
            )
            guard case .gatedBehindProgression = presentation else {
                Issue.record("Expected gatedBehindProgression for \(record.step) when gate is locked.")
                continue
            }
        }
    }

    @Test func presentationAuthoringPendingForPlaceholderRecord() {
        let service = VaccineExplainerService()
        // Default catalog ships all .placeholder records.
        for record in service.catalog {
            let presentation = service.presentation(
                for: record,
                gateOpen: true,
                parentConsented: true
            )
            guard case .authoringPending = presentation else {
                Issue.record("Expected authoringPending for placeholder \(record.step).")
                continue
            }
        }
    }

    @Test func presentationAuthoringPendingForDraftAwaitingReview() {
        // Even with draft prose, reviewer-signoff is required before the
        // step renders to the kid.
        let catalog = VaccineExplainerStep.allCases.map {
            VaccineExplainerStepRecord(step: $0, authoring: .draftAwaitingReview)
        }
        let service = VaccineExplainerService(catalog: catalog)
        for record in service.catalog {
            let presentation = service.presentation(
                for: record,
                gateOpen: true,
                parentConsented: true
            )
            guard case .authoringPending = presentation else {
                Issue.record("Expected authoringPending for draftAwaitingReview \(record.step).")
                continue
            }
        }
    }

    @Test func presentationReadyOnlyWhenReviewerSignedOffAndGateOpenAndConsented() {
        let catalog = VaccineExplainerStep.allCases.map {
            VaccineExplainerStepRecord(step: $0, authoring: .reviewerSignedOff)
        }
        let service = VaccineExplainerService(catalog: catalog)
        for record in service.catalog {
            let presentation = service.presentation(
                for: record,
                gateOpen: true,
                parentConsented: true
            )
            guard case .ready = presentation else {
                Issue.record("Expected ready for reviewerSignedOff \(record.step) with all gates open.")
                continue
            }
        }
    }

    @Test func recordForStepRetrievesCanonicalCopy() {
        let service = VaccineExplainerService()
        for step in VaccineExplainerStep.allCases {
            let record = service.record(for: step)
            #expect(record?.step == step)
        }
    }

    @Test func explainerStepsTraumaSafeRegister() {
        // Per ADR-016 SAMHSA TIP 57 framing, vaccine-explainer step titles
        // + primitives must avoid warfare / shame / threat lexicon.
        let stoplist = [
            "fight", "attack", "destroy", "kill", " war",
            "enemy", "battle", "weapon",
            "failure", "should ", "must ", "behind",
            "scary", "germ", "panic", "horror", "danger",
        ]
        for step in VaccineExplainerStep.allCases {
            let combined = (step.displayTitle + " " + step.primitive).lowercased()
            for word in stoplist {
                #expect(!combined.contains(word),
                        "Vaccine explainer step '\(step.rawValue)' must not surface '\(word.trimmingCharacters(in: .whitespaces))' (trauma-safe register).")
            }
        }
    }

    @Test func explainerStepRawValuesAreStable() {
        // Raw values are load-bearing for the placeholder catalog's JSON
        // round-trip + Codable surface. Renaming a case would break the
        // wire format.
        #expect(VaccineExplainerStep.introduction.rawValue == "introduction")
        #expect(VaccineExplainerStep.antibodyPriming.rawValue == "antibodyPriming")
        #expect(VaccineExplainerStep.memoryFormation.rawValue == "memoryFormation")
        #expect(VaccineExplainerStep.boosterRationale.rawValue == "boosterRationale")
        #expect(VaccineExplainerStep.allCases.count == 4)
    }

    @Test func authoringStateRoundTripsViaCodable() throws {
        // Future external authoring + sync pathway needs Codable round-trip
        // stability for the authoring state.
        let original = VaccineExplainerStepRecord(
            step: .memoryFormation,
            authoring: .reviewerSignedOff
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(VaccineExplainerStepRecord.self, from: data)
        #expect(decoded == original)
    }
}
