import Foundation
import Testing
import Models
@testable import Services

@Suite("PhaseBoundaryExplainerService")
@MainActor
struct PhaseBoundaryExplainerServiceTests {
    @Test func canonicalCatalogShipsThreeNotesInOrder() {
        let service = PhaseBoundaryExplainerService()
        let notes = service.catalog.map(\.note)
        // Order is load-bearing: disease-story → historical context →
        // global tour (lowest session-floor first).
        #expect(notes == [.diseaseStoryArcs, .historicalContextCards, .globalMicrobiomeTour])
    }

    @Test func defaultAuthoringIsPlaceholderForAllNotes() {
        // Trauma-informed gate per ADR-016: every boundary explainer
        // ships as `.placeholder` until reviewer-signoff lands. Pin so
        // future catalog edits don't accidentally ship draft prose.
        let service = PhaseBoundaryExplainerService()
        for record in service.catalog {
            #expect(record.authoring == .placeholder)
        }
    }

    @Test func gateIDsAlignWithProgressionServiceCanonicalKeys() {
        let service = PhaseBoundaryExplainerService()
        let gateIDs = service.catalog.map(\.gateID)
        // disease-story-microbiome (5 sessions + 5 scene visits) +
        // disease-story-immune (5 sessions + 3 immune runs) +
        // global-microbiome-tour (8 sessions + 4 ecologies) — same keys
        // as ProgressionService.canonicalGates per PR #137.
        #expect(gateIDs.contains("disease-story-microbiome"))
        #expect(gateIDs.contains("disease-story-immune"))
        #expect(gateIDs.contains("global-microbiome-tour"))
    }

    @Test func consentRequirementMatchesADR016() {
        // ADR-016 trauma-gated story-axis: disease-story + historical
        // context require parental consent; global-microbiome tour
        // does not (ecology + adaptation framing).
        let service = PhaseBoundaryExplainerService()
        let diseaseNote = try #require(service.record(for: .diseaseStoryArcs))
        let historicalNote = try #require(service.record(for: .historicalContextCards))
        let tourNote = try #require(service.record(for: .globalMicrobiomeTour))
        #expect(diseaseNote.requiresConsent)
        #expect(historicalNote.requiresConsent)
        #expect(!tourNote.requiresConsent)
    }

    @Test func presentationNotReachedWhenGateClosed() {
        let service = PhaseBoundaryExplainerService()
        let record = try #require(service.record(for: .diseaseStoryArcs))
        let result = service.presentation(for: record, gateOpen: false, parentConsented: false)
        guard case .notReached = result else {
            Issue.record("expected .notReached when gate closed; got \(result)")
            return
        }
    }

    @Test func presentationAwaitingConsentWhenGateOpenButNoConsent() {
        let service = PhaseBoundaryExplainerService()
        let record = try #require(service.record(for: .diseaseStoryArcs))
        let result = service.presentation(for: record, gateOpen: true, parentConsented: false)
        guard case .awaitingConsent = result else {
            Issue.record("expected .awaitingConsent for consent-required gate-open no-consent; got \(result)")
            return
        }
    }

    @Test func presentationReadyToInviteWhenGateOpenAndConsentGranted() {
        let service = PhaseBoundaryExplainerService()
        let record = try #require(service.record(for: .diseaseStoryArcs))
        let result = service.presentation(for: record, gateOpen: true, parentConsented: true)
        guard case .readyToInvite = result else {
            Issue.record("expected .readyToInvite; got \(result)")
            return
        }
    }

    @Test func presentationReadyToInviteForNonConsentNoteWithoutConsent() {
        // Global-microbiome tour has requiresConsent = false. Even if the
        // grown-up hasn't granted disease-story consent, the tour boundary
        // surfaces as .readyToInvite once the gate opens.
        let service = PhaseBoundaryExplainerService()
        let record = try #require(service.record(for: .globalMicrobiomeTour))
        let result = service.presentation(for: record, gateOpen: true, parentConsented: false)
        guard case .readyToInvite = result else {
            Issue.record("non-consent note should surface .readyToInvite without consent; got \(result)")
            return
        }
    }

    @Test func acknowledgeCollapsesToAlreadyAccepted() {
        let service = PhaseBoundaryExplainerService()
        let record = try #require(service.record(for: .globalMicrobiomeTour))
        service.acknowledge(.globalMicrobiomeTour)
        let result = service.presentation(for: record, gateOpen: true, parentConsented: false)
        guard case .alreadyAccepted = result else {
            Issue.record("expected .alreadyAccepted after acknowledge; got \(result)")
            return
        }
    }

    @Test func acknowledgeIsIdempotent() {
        let service = PhaseBoundaryExplainerService()
        service.acknowledge(.globalMicrobiomeTour)
        service.acknowledge(.globalMicrobiomeTour)
        #expect(service.hasAcknowledged(.globalMicrobiomeTour))
    }

    @Test func resetAcknowledgementsRestoresReadyState() {
        let service = PhaseBoundaryExplainerService()
        service.acknowledge(.globalMicrobiomeTour)
        service.resetAcknowledgements()
        #expect(!service.hasAcknowledged(.globalMicrobiomeTour))
        let record = try #require(service.record(for: .globalMicrobiomeTour))
        let result = service.presentation(for: record, gateOpen: true, parentConsented: false)
        guard case .readyToInvite = result else {
            Issue.record("expected .readyToInvite after reset; got \(result)")
            return
        }
    }

    @Test func recordLookupReturnsNilForMissingNote() {
        // Defensive: empty catalog returns nil lookup.
        let service = PhaseBoundaryExplainerService(catalog: [])
        #expect(service.record(for: .diseaseStoryArcs) == nil)
    }

    @Test func displayTitlesAvoidAlarmFraming() {
        // Trauma-informed register stoplist — every boundary title is
        // grown-up-facing but appears alongside kid-facing surfaces; the
        // tokens below would crash the SAMHSA TIP 57 validate-then-inform
        // register and shouldn't slip into a catalog override either.
        let stoplist = [
            "warning",
            "danger",
            "scary",
            "shouldn't",
            "wrong",
            "broken",
            "failure",
        ]
        let service = PhaseBoundaryExplainerService()
        for record in service.catalog {
            let title = record.displayTitle.lowercased()
            for token in stoplist {
                #expect(
                    !title.contains(token),
                    "boundary note \(record.note.rawValue) title contains alarm token '\(token)'"
                )
            }
        }
    }

    @Test func codableRoundtripPreservesRecord() throws {
        let original = PhaseBoundaryNoteRecord(
            note: .diseaseStoryArcs,
            authoring: .reviewerSignedOff
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PhaseBoundaryNoteRecord.self, from: encoded)
        #expect(decoded == original)
    }

    @Test func customCatalogReplacesDefaults() {
        // Test environments should be able to inject a custom catalog
        // (e.g., a fixture with `.reviewerSignedOff` authoring to test
        // the ready-to-invite path). Pin the override semantic.
        let custom = [
            PhaseBoundaryNoteRecord(note: .diseaseStoryArcs, authoring: .reviewerSignedOff),
        ]
        let service = PhaseBoundaryExplainerService(catalog: custom)
        #expect(service.catalog.count == 1)
        #expect(service.catalog.first?.authoring == .reviewerSignedOff)
    }
}
