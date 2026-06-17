import Foundation
import Testing
@testable import Services
@testable import Models

@Suite("QuestionKitService")
nonisolated struct QuestionKitServiceTests {
    @Test func loadsKit01FromBundle() throws {
        let service = QuestionKitService()
        let result = service.loadKit(slug: "microbiology-basics")
        guard case .success(let kit) = result else {
            Issue.record("Expected success, got \(result)")
            return
        }
        #expect(kit.kitNumber == 1)
        #expect(kit.slug == "microbiology-basics")
        #expect(!kit.questions.isEmpty)
        // Every question must have a correctIndex that points into choices.
        for question in kit.questions {
            #expect(question.choices.indices.contains(question.correctIndex))
        }
    }

    @Test func unknownSlugReturnsError() {
        let service = QuestionKitService()
        let result = service.loadKit(slug: "this-kit-does-not-exist")
        guard case .failure = result else {
            Issue.record("Expected failure, got \(result)")
            return
        }
    }

    @Test func loadAllPhase1KitsCoversBundledSet() {
        let service = QuestionKitService()
        let kits = service.loadAllPhase1Kits()
        #expect(kits.count == QuestionKitService.phase1KitSlugs.count)
    }

    @Test func loadsKit02MicrobiomeFromBundle() throws {
        let service = QuestionKitService()
        let result = service.loadKit(slug: "microbiome")
        guard case .success(let kit) = result else {
            Issue.record("Expected success, got \(result)")
            return
        }
        #expect(kit.kitNumber == 2)
        #expect(kit.slug == "microbiome")
        #expect(!kit.questions.isEmpty)
        for question in kit.questions {
            #expect(question.choices.indices.contains(question.correctIndex))
        }
    }

    @Test func loadsKit03ImmuneDefenseFromBundle() throws {
        let service = QuestionKitService()
        let result = service.loadKit(slug: "immune-defense")
        guard case .success(let kit) = result else {
            Issue.record("Expected success, got \(result)")
            return
        }
        #expect(kit.kitNumber == 3)
        #expect(kit.slug == "immune-defense")
        #expect(!kit.questions.isEmpty)
        for question in kit.questions {
            #expect(question.choices.indices.contains(question.correctIndex))
        }
    }

    @Test func loadsKit04BeneficialMicrobesFromBundle() throws {
        let service = QuestionKitService()
        let result = service.loadKit(slug: "beneficial-microbes")
        guard case .success(let kit) = result else {
            Issue.record("Expected success, got \(result)")
            return
        }
        #expect(kit.kitNumber == 4)
        #expect(kit.slug == "beneficial-microbes")
        #expect(!kit.questions.isEmpty)
        for question in kit.questions {
            #expect(question.choices.indices.contains(question.correctIndex))
        }
    }

    @Test func phase1KitSlugsReachesPhase1Target() {
        // Phase-1 ships kits 01-04 per Docs/FEATURE_PLAN.md § Gamification.
        // Guards against accidental regression while Phase-2 kits land later.
        #expect(QuestionKitService.phase1KitSlugs.count == 4)
    }

    @Test func everyPhase1KitNumberMatchesCanonicalOrder() {
        let service = QuestionKitService()
        let kits = service.loadAllPhase1Kits()
        // Canonical: kitNumber == 1-based index in phase1KitSlugs.
        for (index, kit) in kits.enumerated() {
            #expect(kit.kitNumber == index + 1, "kit \(kit.slug) kitNumber=\(kit.kitNumber) but expected \(index + 1)")
        }
    }

    @Test func questionIDsAreUniqueAcrossPhase1Kits() {
        let service = QuestionKitService()
        let kits = service.loadAllPhase1Kits()
        var seen = Set<UUID>()
        for kit in kits {
            for question in kit.questions {
                #expect(!seen.contains(question.id), "Duplicate question id \(question.id) in kit \(kit.slug)")
                seen.insert(question.id)
            }
        }
    }

    @Test func loadsKit05AdaptiveImmunityFromBundle() throws {
        let service = QuestionKitService()
        let result = service.loadKit(slug: "adaptive-immunity")
        guard case .success(let kit) = result else {
            Issue.record("Expected success, got \(result)")
            return
        }
        #expect(kit.kitNumber == 5)
        #expect(kit.slug == "adaptive-immunity")
        #expect(!kit.questions.isEmpty)
        for question in kit.questions {
            #expect(question.choices.indices.contains(question.correctIndex))
        }
    }

    @Test func phase2KitSlugsContainsAdaptiveImmunity() {
        // Phase-2 ships kit 05 alongside the BCellAntibodyMatchScene + the
        // AdaptiveImmunityUnlock progression curve + mentor cues. Kits 06-08
        // (oral / skin / soil microbiome) ship ahead of the corresponding
        // microbiome scenes so the kit-progress strip carries the full set.
        #expect(QuestionKitService.phase2KitSlugs.contains("adaptive-immunity"))
    }

    @Test func loadsKit06OralMicrobiomeFromBundle() throws {
        let service = QuestionKitService()
        let result = service.loadKit(slug: "oral-microbiome")
        guard case .success(let kit) = result else {
            Issue.record("Expected success, got \(result)")
            return
        }
        #expect(kit.kitNumber == 6)
        #expect(kit.slug == "oral-microbiome")
        #expect(!kit.questions.isEmpty)
        for question in kit.questions {
            #expect(question.choices.indices.contains(question.correctIndex))
        }
    }

    @Test func loadsKit07SkinMicrobiomeFromBundle() throws {
        let service = QuestionKitService()
        let result = service.loadKit(slug: "skin-microbiome")
        guard case .success(let kit) = result else {
            Issue.record("Expected success, got \(result)")
            return
        }
        #expect(kit.kitNumber == 7)
        #expect(kit.slug == "skin-microbiome")
        #expect(!kit.questions.isEmpty)
        for question in kit.questions {
            #expect(question.choices.indices.contains(question.correctIndex))
        }
    }

    @Test func loadsKit08SoilMicrobiomeFromBundle() throws {
        let service = QuestionKitService()
        let result = service.loadKit(slug: "soil-microbiome")
        guard case .success(let kit) = result else {
            Issue.record("Expected success, got \(result)")
            return
        }
        #expect(kit.kitNumber == 8)
        #expect(kit.slug == "soil-microbiome")
        #expect(!kit.questions.isEmpty)
        for question in kit.questions {
            #expect(question.choices.indices.contains(question.correctIndex))
        }
    }

    @Test func phase2KitSlugsReachesPhase2Target() {
        // Phase-2 ships all 4 kits (05 adaptive + 06 oral + 07 skin + 08 soil)
        // per Docs/FEATURE_PLAN.md § Phase 2. Guards against future regression.
        #expect(QuestionKitService.phase2KitSlugs.count == 4)
        #expect(QuestionKitService.phase2KitSlugs == [
            "adaptive-immunity",
            "oral-microbiome",
            "skin-microbiome",
            "soil-microbiome"
        ])
    }

    @Test func everyPhase2KitNumberMatchesCanonicalOrder() {
        let service = QuestionKitService()
        let kits = service.loadAllPhase2Kits()
        // Canonical: kit05 → kitNumber 5; kit06 → 6; kit07 → 7; kit08 → 8.
        for (index, kit) in kits.enumerated() {
            #expect(kit.kitNumber == index + 5,
                    "kit \(kit.slug) kitNumber=\(kit.kitNumber) but expected \(index + 5)")
        }
    }

    @Test func phase2EcologyKitsCarryEcologyCurriculumStandards() {
        let service = QuestionKitService()
        // Ecology kits (oral / skin / soil) should surface NGSS MS-LS2-2
        // (interactions in ecosystems) per Docs/TECHNICAL_DESIGN.md
        // § Curriculum — that's the standard the microbiome-as-ecology
        // pedagogy maps to.
        for slug in ["oral-microbiome", "skin-microbiome", "soil-microbiome"] {
            guard case .success(let kit) = service.loadKit(slug: slug) else {
                Issue.record("\(slug) should load")
                continue
            }
            let tagged = kit.questions.compactMap(\.curriculumStandard)
            #expect(tagged.contains(where: { $0.contains("MS-LS2") }),
                    "Kit \(slug) must surface at least one MS-LS2-* standard for ecology coverage.")
        }
    }

    @Test func phase2EcologyKitsTraumaInformedRegisterStoplist() {
        let service = QuestionKitService()
        // Pin trauma-informed register across the 3 new ecology kits. Each
        // ecology has its own register-sensitive vocabulary:
        //
        // - Oral (kit 06): no warfare register; cavities framed as ecology,
        //   not blame
        // - Skin (kit 07): no body-image-shame register; eczema framed with
        //   care, not failure
        // - Soil (kit 08): no warfare register; decomposers are quiet
        //   helpers, not destroyers
        let warfareStoplist = ["fight", "attack", "destroy", "kill", "war",
                               "enemy", "battle", "weapon", "soldier",
                               "warrior"]
        let bodyShameStoplist = ["gross", "dirty", "ugly", "ashamed",
                                 "blemish", "filthy"]
        let blameStoplist = ["lazy", "careless", "should have brushed",
                             "wrong choice", "your fault"]

        for slug in ["oral-microbiome", "skin-microbiome", "soil-microbiome"] {
            guard case .success(let kit) = service.loadKit(slug: slug) else {
                Issue.record("\(slug) should load")
                continue
            }
            for question in kit.questions {
                let blob = ([question.prompt, question.explanation] + question.choices)
                    .joined(separator: " ")
                    .lowercased()
                for forbidden in warfareStoplist + bodyShameStoplist + blameStoplist {
                    #expect(!blob.contains(forbidden),
                            "Kit \(slug) question \(question.id) contains forbidden token '\(forbidden)'")
                }
            }
        }
    }

    @Test func loadAllPhase2KitsCoversBundledSet() {
        let service = QuestionKitService()
        let kits = service.loadAllPhase2Kits()
        #expect(kits.count == QuestionKitService.phase2KitSlugs.count)
    }

    @Test func allKitSlugsUnionsAllPhases() {
        let all = QuestionKitService.allKitSlugs
        let expected = QuestionKitService.phase1KitSlugs
            + QuestionKitService.phase2KitSlugs
            + QuestionKitService.phase3KitSlugs
        #expect(all == expected)
        // Uniqueness across phases — no kit slug should appear twice.
        #expect(Set(all).count == all.count)
    }

    @Test func phase3KitSlugsCoversFourCanonicalSlots() {
        // Phase 3 ships kits 09-12 per Docs/FEATURE_PLAN.md § Phase 3.
        // They ship as placeholders (.draftAwaitingReview) until external
        // SAMHSA TIP 57 reviewer signoff lands per ADR-016.
        #expect(QuestionKitService.phase3KitSlugs.count == 4)
        #expect(QuestionKitService.phase3KitSlugs == [
            "vaccines",
            "herd-immunity",
            "hygiene",
            "public-health"
        ])
    }

    @Test func phase3KitsShipAsDraftAwaitingReview() {
        // The 4 Phase 3 kits MUST ship as placeholder content gated behind
        // reviewer signoff. If any of these flip to .reviewerSignedOff, it
        // means real content has landed — which should only happen via a
        // PR that ALSO updates the corresponding tests below to reflect the
        // shipped surface (not by accident).
        let service = QuestionKitService()
        for slug in QuestionKitService.phase3KitSlugs {
            guard case .success(let kit) = service.loadKit(slug: slug) else {
                Issue.record("Phase 3 kit \(slug) failed to load")
                continue
            }
            #expect(kit.authoring == .draftAwaitingReview,
                    "Phase 3 kit \(slug) must ship as draftAwaitingReview until reviewer signoff lands.")
        }
    }

    @Test func phase3KitsHavePlaceholderQuestionStubs() {
        // Each scaffold kit ships a 1-question stub with a deterministic
        // "Reviewer-signoff pending" body. The stub keeps the JSON valid
        // (so the QuestionKit decoder succeeds) without committing to any
        // factual claim that hasn't been reviewer-signed-off.
        let service = QuestionKitService()
        for slug in QuestionKitService.phase3KitSlugs {
            guard case .success(let kit) = service.loadKit(slug: slug) else {
                Issue.record("Phase 3 kit \(slug) failed to load")
                continue
            }
            #expect(kit.questions.count == 1,
                    "Phase 3 placeholder \(slug) ships a 1-question stub.")
            for question in kit.questions {
                #expect(question.prompt.contains("Reviewer-signoff pending"),
                        "Placeholder question must surface the reviewer-signoff sentinel.")
                #expect(question.explanation.contains("Reviewer-signoff pending"),
                        "Placeholder explanation must surface the reviewer-signoff sentinel.")
            }
        }
    }

    @Test func loadAllPhase3KitsFiltersOutUnreviewedDrafts() {
        // The canonical accessor MUST drop any kit that isn't
        // .reviewerSignedOff. With the current scaffold all 4 Phase 3 kits
        // are .draftAwaitingReview, so the returned array is empty — the
        // kid surface never sees unreviewed content.
        let service = QuestionKitService()
        #expect(service.loadAllPhase3Kits().isEmpty,
                "Phase 3 kits in draft state must be filtered out of the load accessor.")
    }

    @Test func loadAllShippedKitsCoversPhase1AndPhase2OnlyUntilReviewerSignoff() {
        // The cross-phase accessor returns Phase 1 + Phase 2 kits only while
        // Phase 3 sits in draft. This is the canonical accessor for UI
        // surfaces that span phases — they get the shipped surface only.
        let service = QuestionKitService()
        let shipped = service.loadAllShippedKits()
        let expectedSize = QuestionKitService.phase1KitSlugs.count
            + QuestionKitService.phase2KitSlugs.count
        #expect(shipped.count == expectedSize,
                "loadAllShippedKits must drop Phase 3 drafts until reviewer signoff.")
    }

    @Test func phase3KitsAuthoringRoundTripsViaCodable() throws {
        // Future content drops will flip kit JSONs from draftAwaitingReview
        // to reviewerSignedOff. The roundtrip pins that the field is
        // encoded + decoded correctly when authoring changes.
        let original = QuestionKit(
            id: UUID(),
            slug: "test",
            title: "Test",
            summary: "Test",
            kitNumber: 99,
            questions: [],
            authoring: .reviewerSignedOff
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(QuestionKit.self, from: data)
        #expect(decoded.authoring == .reviewerSignedOff)
    }

    @Test func phase1KitDecoderDefaultsAuthoringToReviewerSignedOff() {
        // Phase 1 + Phase 2 kits omit the authoring field in their JSON.
        // The decoder must default to .reviewerSignedOff so already-shipped
        // kits surface unchanged.
        let service = QuestionKitService()
        guard case .success(let kit) = service.loadKit(slug: "microbiology-basics") else {
            Issue.record("microbiology-basics should load")
            return
        }
        #expect(kit.authoring == .reviewerSignedOff,
                "Phase 1 kits omit the authoring field; decoder must default to reviewerSignedOff.")
    }

    @Test func kit05CarriesAdaptiveImmunityCurriculumStandards() {
        let service = QuestionKitService()
        guard case .success(let kit) = service.loadKit(slug: "adaptive-immunity") else {
            Issue.record("kit05 should load")
            return
        }
        // MS-LS1-3 (immune system as subsystem) is the canonical Phase-2
        // standard mapping per Docs/TECHNICAL_DESIGN.md § Curriculum.
        let tagged = kit.questions.compactMap(\.curriculumStandard)
        #expect(tagged.contains("NGSS MS-LS1-3"),
                "Kit 05 must surface MS-LS1-3 — the adaptive-immunity standard.")
    }

    @Test func kit05TraumaInformedRegisterStoplist() {
        let service = QuestionKitService()
        guard case .success(let kit) = service.loadKit(slug: "adaptive-immunity") else {
            Issue.record("kit05 should load")
            return
        }
        // Pin the no-warfare-vocabulary invariant inherited from PR #104's
        // AdaptiveImmuneHypothesis + PR #105's BCellAntibodyMatchScene. The
        // body LEARNS and REMEMBERS in adaptive immunity — it doesn't fight.
        let stoplist = ["fight", "attack", "destroy", "kill", "war",
                        "enemy", "battle", "weapon", "soldier", "warrior"]
        for question in kit.questions {
            let blob = ([question.prompt, question.explanation] + question.choices)
                .joined(separator: " ")
                .lowercased()
            for forbidden in stoplist {
                #expect(!blob.contains(forbidden),
                        "Kit 05 question \(question.id) contains forbidden warfare token '\(forbidden)'")
            }
        }
    }

    @Test func questionIDsAreUniqueAcrossAllShippedKits() {
        let service = QuestionKitService()
        let kits = service.loadAllPhase1Kits() + service.loadAllPhase2Kits()
        var seen = Set<UUID>()
        for kit in kits {
            for question in kit.questions {
                #expect(!seen.contains(question.id),
                        "Duplicate question id \(question.id) in kit \(kit.slug)")
                seen.insert(question.id)
            }
        }
    }
}
