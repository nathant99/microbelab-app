import Foundation
import Testing
@testable import AIMentor
@testable import Models

@Suite("VeeMentor")
@MainActor
struct VeeMentorTests {
    private func fixture() -> VeeMentor {
        let microbe = MicrobeCharacter(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            slug: "lacto",
            displayName: "Lacto",
            kingdom: .bacteria,
            role: .beneficial,
            preferredEnvironment: .colon,
            growthRate: GrowthRate(onFiber: 0.6, onSugar: 0.1, onBalanced: 0.4, onNone: -0.1),
            catchphrase: "Friend in your food. Friend in your gut.",
            factCard: "Lactobacillus species ferment milk into yogurt.",
            firstKit: 1
        )
        return VeeMentor(microbes: [microbe])
    }

    @Test func mentorDisplayNameIsCilia() {
        // Renamed from Vee/Dr. Quark per HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.
        #expect(VeeMentor.displayName == "Cilia")
    }

    @Test func catchphraseForKnownSlug() {
        let mentor = fixture()
        #expect(mentor.catchphrase(for: "lacto") == "Friend in your food. Friend in your gut.")
    }

    @Test func catchphraseForUnknownSlugIsNil() {
        let mentor = fixture()
        #expect(mentor.catchphrase(for: "missing") == nil)
    }

    @Test func factCardForKnownSlug() {
        let mentor = fixture()
        #expect(mentor.factCard(for: "lacto")?.contains("Lactobacillus") == true)
    }
}
