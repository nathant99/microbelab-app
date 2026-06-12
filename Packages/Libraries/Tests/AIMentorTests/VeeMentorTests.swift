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

    @Test func fallbackMicrobeFactWiresStaticCatalog() {
        let mentor = fixture()
        let fact = mentor.fallbackMicrobeFact(for: "lacto")
        #expect(fact?.factBody.contains("Lactobacillus") == true)
        #expect(fact?.socraticPrompt.contains("Lacto") == true)
    }

    @Test func fallbackMicrobeFactForUnknownSlugIsNil() {
        let mentor = fixture()
        #expect(mentor.fallbackMicrobeFact(for: "missing") == nil)
    }

    @Test func fallbackZoomCueCoversAllTiers() {
        let mentor = fixture()
        for tier in ZoomTier.allCases {
            let cue = mentor.fallbackZoomCue(for: tier)
            #expect(!cue.reaction.isEmpty)
            #expect(!cue.lookForHint.isEmpty)
            // Trauma-safe register: no exclamation points in mentor reactions.
            #expect(!cue.reaction.contains("!"))
        }
    }

    @Test func fallbackEcologyHypothesisCoversAllModes() {
        let mentor = fixture()
        for mode in FeedingMode.allCases {
            let hyp = mentor.fallbackEcologyHypothesis(for: mode)
            #expect(!hyp.observation.isEmpty)
            #expect(!hyp.hypothesis.isEmpty)
        }
    }

    @Test func voiceLineFallsBackToCatchphraseWhenNoLinesAuthored() {
        // The fixture above doesn't set voiceLines — mentor must fall back
        // to the catchphrase.
        let mentor = fixture()
        let line = mentor.voiceLine(for: "lacto", rotation: 0)
        #expect(line == "Friend in your food. Friend in your gut.")
    }

    @Test func voiceLineRotatesAcrossAuthoredLines() {
        let microbe = MicrobeCharacter(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            slug: "voicy",
            displayName: "Voicy",
            kingdom: .bacteria,
            role: .beneficial,
            preferredEnvironment: .colon,
            growthRate: GrowthRate(onFiber: 0.5, onSugar: 0.1, onBalanced: 0.3, onNone: 0.0),
            catchphrase: "Hi",
            factCard: "Authored fact",
            firstKit: 1,
            voiceLines: ["line A", "line B", "line C"]
        )
        let mentor = VeeMentor(microbes: [microbe])
        #expect(mentor.voiceLine(for: "voicy", rotation: 0) == "line A")
        #expect(mentor.voiceLine(for: "voicy", rotation: 1) == "line B")
        #expect(mentor.voiceLine(for: "voicy", rotation: 2) == "line C")
        // Rotation wraps cleanly.
        #expect(mentor.voiceLine(for: "voicy", rotation: 3) == "line A")
    }
}
