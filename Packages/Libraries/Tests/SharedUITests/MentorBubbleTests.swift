import Testing
import Foundation
import Models
@testable import SharedUI

/// Surface-area smoke tests for `MentorBubble`'s featured-microbe
/// turn-prefix path (post PR #200 portrait seam). The default path
/// (no featured microbe) is exercised across 7 call sites in
/// AppFeature; these tests pin the optional surface so future
/// consumer wiring (cast voicing UI, DN-S Phase 1 Move D) inherits a
/// stable contract.
@Suite("MentorBubble (cast portrait turn-prefix surface)")
struct MentorBubbleTests {

    private func makeMicrobe(slug: String = "lacto", displayName: String = "Lacto") -> MicrobeCharacter {
        MicrobeCharacter(
            id: UUID(),
            slug: slug,
            displayName: displayName,
            kingdom: .bacteria,
            role: .beneficial,
            preferredEnvironment: .colon,
            growthRate: GrowthRate(onFiber: 0.5, onSugar: -0.2, onBalanced: 0.2, onNone: 0),
            catchphrase: "I help digest milk.",
            factCard: "Lacto ferments lactose into lactic acid.",
            firstKit: 1
        )
    }

    @Test("default init preserves the no-portrait shape used by every existing call site")
    func defaultInitNoPortrait() {
        let bubble = MentorBubble(message: "Try fiber today.")
        #expect(bubble.mentorName == "Cilia")
        #expect(bubble.featuredMicrobe == nil)
        #expect(bubble.featuredMicrobeIsDiscovered)
    }

    @Test("featured microbe init carries the value type AND defaults isDiscovered=true")
    func featuredMicrobeInit() {
        let microbe = makeMicrobe()
        let bubble = MentorBubble(message: "Lacto is hanging around today.", featuredMicrobe: microbe)
        #expect(bubble.featuredMicrobe?.slug == "lacto")
        #expect(bubble.featuredMicrobeIsDiscovered)
    }

    @Test("explicit isDiscovered=false flows through to the portrait surface")
    func undiscoveredFeaturedMicrobe() {
        let microbe = makeMicrobe()
        let bubble = MentorBubble(
            message: "Try the microscope.",
            featuredMicrobe: microbe,
            featuredMicrobeIsDiscovered: false
        )
        #expect(bubble.featuredMicrobeIsDiscovered == false)
    }

    @Test("custom portrait bundle overrides .main — caller can hand a SharedUI .module bundle when assets land there")
    func customPortraitBundle() {
        let microbe = makeMicrobe()
        let stubBundle = Bundle(for: BundleStub.self)
        let bubble = MentorBubble(
            message: "Hello.",
            featuredMicrobe: microbe,
            portraitBundle: stubBundle
        )
        #expect(bubble.portraitBundle === stubBundle)
    }

    private final class BundleStub {}
}
