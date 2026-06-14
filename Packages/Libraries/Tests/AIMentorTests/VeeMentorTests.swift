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

    @Test func fallbackAdaptiveImmuneHypothesisCoversAllScenarios() {
        let mentor = fixture()
        for scenario in AdaptiveImmuneScenario.allCases {
            let hyp = mentor.fallbackAdaptiveImmuneHypothesis(for: scenario)
            #expect(!hyp.observation.isEmpty)
            #expect(!hyp.memoryHypothesis.isEmpty)
        }
    }

    @Test func fallbackAdaptiveImmuneHypothesisAvoidsWarfareFraming() {
        // Trauma-informed posture per Docs/TECHNICAL_DESIGN.md § Trauma-
        // Informed Design Posture: adaptive immunity surfaces as the
        // body's library of shapes, NEVER as warfare. Authored fallback
        // content must pass the stoplist regardless of the AI surface
        // (the AI prompt also forbids it, but the fallback is the
        // load-bearing trauma-safe default).
        let stoplist = [
            "fight",
            "attack",
            "destroy",
            "kill",
            "war",
            "enemy",
            "battle",
            "weapon",
            "soldier",
            "warrior",
        ]
        let mentor = fixture()
        for scenario in AdaptiveImmuneScenario.allCases {
            let hyp = mentor.fallbackAdaptiveImmuneHypothesis(for: scenario)
            let combined = (hyp.observation + " " + hyp.memoryHypothesis).lowercased()
            for token in stoplist {
                #expect(!combined.contains(token), "scenario=\(scenario) contained warfare-stoplist token '\(token)': \"\(combined)\"")
            }
        }
    }

    @Test func fallbackAdaptiveImmuneHypothesisUsesHedgingLanguage() {
        // Per .claude/rules/ai-content.md the fallback content uses
        // hedging language ("often", "usually", "many", "sometimes")
        // rather than absolute claims — adaptive immunity is messy and
        // the kid-readable register reflects that.
        let hedgers = ["often", "usually", "many", "sometimes", "may", "might", "tend"]
        let mentor = fixture()
        for scenario in AdaptiveImmuneScenario.allCases {
            let hyp = mentor.fallbackAdaptiveImmuneHypothesis(for: scenario)
            let body = (hyp.observation + " " + hyp.memoryHypothesis).lowercased()
            let anyHedge = hedgers.contains { body.contains($0) }
            #expect(anyHedge, "scenario=\(scenario) fallback lacked hedging language: \"\(body)\"")
        }
    }

    @Test func fallbackAdaptiveImmuneHypothesisUsesShapeMatchingRegister() {
        // The pedagogy beat for adaptive immunity is shape-matching +
        // memory. The fallback content should reference at least one of
        // these registers (so the kid maps the line to the gameplay).
        let registers = ["shape", "match", "memory", "recogniz", "fit", "library", "note"]
        let mentor = fixture()
        for scenario in AdaptiveImmuneScenario.allCases {
            let hyp = mentor.fallbackAdaptiveImmuneHypothesis(for: scenario)
            let body = (hyp.observation + " " + hyp.memoryHypothesis).lowercased()
            let anyRegister = registers.contains { body.contains($0) }
            #expect(anyRegister, "scenario=\(scenario) fallback lacked shape-matching register: \"\(body)\"")
        }
    }

    @Test func adaptiveImmuneScenarioRawValuesAreStable() {
        // Raw values are load-bearing because the async `adaptiveImmuneHypothesis`
        // method interpolates them into the LLM prompt. Renaming a case
        // would silently break the prompt's pedagogy framing.
        #expect(AdaptiveImmuneScenario.firstEncounter.rawValue == "firstEncounter")
        #expect(AdaptiveImmuneScenario.matchedShape.rawValue == "matchedShape")
        #expect(AdaptiveImmuneScenario.recallFromMemory.rawValue == "recallFromMemory")
        #expect(AdaptiveImmuneScenario.allCases.count == 3)
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

@Suite("VeeMentor.recallCue")
@MainActor
struct VeeMentorRecallCueTests {
    private func mentor() -> VeeMentor {
        VeeMentor(microbes: [
            MicrobeCharacter(
                id: UUID(uuidString: "00000000-0000-0000-0000-00000000ABCD")!,
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
        ])
    }

    @Test func recallCueForUnknownSlugReturnsNil() {
        // Caller can fall back to the default mentor copy.
        #expect(mentor().recallCue(for: "missing", daysSinceLastSeen: 0) == nil)
    }

    @Test func sameDayCueQuotesDisplayNameAndUsesEarlierFraming() {
        let line = mentor().recallCue(for: "lacto", daysSinceLastSeen: 0) ?? ""
        #expect(line.contains("Lacto"))
        #expect(line.contains("earlier today"))
    }

    @Test func yesterdayCueUsesYesterdayFraming() {
        let line = mentor().recallCue(for: "lacto", daysSinceLastSeen: 1) ?? ""
        #expect(line.contains("yesterday"))
    }

    @Test func multiDayCueUsesGentleStillAroundFraming() {
        let line = mentor().recallCue(for: "lacto", daysSinceLastSeen: 4) ?? ""
        #expect(line.contains("Lacto"))
        // Trauma-informed: warm "still around" never "you abandoned us."
        #expect(line.contains("still"))
    }

    @Test func longGapCueAvoidsAbandonmentFraming() {
        let line = mentor().recallCue(for: "lacto", daysSinceLastSeen: 30) ?? ""
        // Make sure we never frame the gap as loss or shame.
        #expect(!line.contains("missed"))
        #expect(!line.contains("abandon"))
        #expect(!line.contains("forgot"))
    }

    @Test func negativeDaysCollapsesToSameDayCopy() {
        // Defensive: a negative offset (clock-skew) should never produce
        // weird out-of-band copy.
        let sameDay = mentor().recallCue(for: "lacto", daysSinceLastSeen: 0) ?? ""
        let negative = mentor().recallCue(for: "lacto", daysSinceLastSeen: -3) ?? ""
        #expect(sameDay == negative)
    }
}
