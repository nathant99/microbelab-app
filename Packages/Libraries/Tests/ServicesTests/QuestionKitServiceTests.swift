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
}
