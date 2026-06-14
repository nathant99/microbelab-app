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
        // (oral / skin / soil microbiome) follow when the corresponding
        // scenes ship.
        #expect(QuestionKitService.phase2KitSlugs.contains("adaptive-immunity"))
    }

    @Test func loadAllPhase2KitsCoversBundledSet() {
        let service = QuestionKitService()
        let kits = service.loadAllPhase2Kits()
        #expect(kits.count == QuestionKitService.phase2KitSlugs.count)
    }

    @Test func allKitSlugsUnionsPhase1AndPhase2() {
        let all = QuestionKitService.allKitSlugs
        #expect(all == QuestionKitService.phase1KitSlugs + QuestionKitService.phase2KitSlugs)
        // Uniqueness across phases — no kit slug should appear twice.
        #expect(Set(all).count == all.count)
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
