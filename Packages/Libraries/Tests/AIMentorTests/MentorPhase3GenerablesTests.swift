import Foundation
import Testing
@testable import AIMentor
@testable import Models

@Suite("VeeMentor.VaccineMechanismCue")
@MainActor
struct VaccineMechanismCueTests {
    private func mentor() -> VeeMentor {
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

    @Test func fallbackCoversAllScenarios() {
        let m = mentor()
        for scenario in VaccineMechanismScenario.allCases {
            let cue = m.fallbackVaccineMechanismCue(for: scenario)
            #expect(!cue.observation.isEmpty)
            #expect(!cue.librariesHypothesis.isEmpty)
        }
    }

    @Test func fallbackAvoidsWarfareAndFearAndShameLexicon() {
        // Per Docs/TECHNICAL_DESIGN.md § Trauma-Informed Design Posture +
        // ADR-016: vaccine mentor surface MUST avoid warfare + fear-induction
        // + shame lexicon — the body's library learns, never fights.
        let stoplist = [
            // Warfare
            "fight", "attack", "destroy", " kill", " war",
            "enemy", "battle", "weapon", "soldier", "warrior",
            // Fear induction
            "scary", "panic", "horror", "danger", " germ",
            // Shame
            " failure", "should ", "must ", " behind", "fell short",
        ]
        let m = mentor()
        for scenario in VaccineMechanismScenario.allCases {
            let cue = m.fallbackVaccineMechanismCue(for: scenario)
            let combined = (cue.observation + " " + cue.librariesHypothesis).lowercased()
            for word in stoplist {
                #expect(!combined.contains(word),
                        "\(scenario) fallback must not surface '\(word.trimmingCharacters(in: .whitespaces))' (trauma-safe register).")
            }
        }
    }

    @Test func fallbackUsesHedgingLanguage() {
        // Per .claude/rules/foundationmodels.md + ai-content.md: vaccine
        // fallback content uses hedging language — never absolute claims.
        let hedges = ["often", "usually", "many", "most", "tends", "may"]
        let m = mentor()
        for scenario in VaccineMechanismScenario.allCases {
            let cue = m.fallbackVaccineMechanismCue(for: scenario)
            let body = cue.librariesHypothesis.lowercased()
            let hasHedge = hedges.contains { body.contains($0) }
            #expect(hasHedge,
                    "\(scenario) hypothesis must use hedging language: \(cue.librariesHypothesis)")
        }
    }

    @Test func fallbackUsesLibraryAndCareRegister() {
        // Per Docs/TECHNICAL_DESIGN.md: vaccine pedagogy surfaces the body's
        // library learning a shape ahead of meeting it live — care + curiosity
        // + library register across all 4 steps.
        let m = mentor()
        let registerHints: [VaccineMechanismScenario: [String]] = [
            .introduction:    ["library", "helper"],
            .antibodyPriming: ["library", "shape", "practice"],
            .memoryFormation: ["note", "recogniz"],
            .boosterRationale: ["care", "patient"],
        ]
        for (scenario, anyHint) in registerHints {
            let cue = m.fallbackVaccineMechanismCue(for: scenario)
            let combined = (cue.observation + " " + cue.librariesHypothesis).lowercased()
            let hits = anyHint.filter { combined.contains($0) }
            #expect(!hits.isEmpty,
                    "\(scenario) fallback should surface at least one of \(anyHint): \(combined)")
        }
    }

    @Test func scenarioRawValuesAreStable() {
        // Raw values are load-bearing because the async accessor interpolates
        // them into the LLM prompt. Renaming silently breaks the pedagogy
        // framing.
        #expect(VaccineMechanismScenario.introduction.rawValue == "introduction")
        #expect(VaccineMechanismScenario.antibodyPriming.rawValue == "antibodyPriming")
        #expect(VaccineMechanismScenario.memoryFormation.rawValue == "memoryFormation")
        #expect(VaccineMechanismScenario.boosterRationale.rawValue == "boosterRationale")
        #expect(VaccineMechanismScenario.allCases.count == 4)
    }

    @Test func scenarioPairsOneToOneWithVaccineExplainerStep() {
        // The 4-case alignment is the load-bearing contract — consumer views
        // map a `VaccineExplainerStep` to a `VaccineMechanismScenario` 1:1
        // via the raw value.
        #expect(VaccineMechanismScenario.allCases.count == VaccineExplainerStep.allCases.count)
        for step in VaccineExplainerStep.allCases {
            #expect(VaccineMechanismScenario(rawValue: step.rawValue) != nil,
                    "Vaccine step \(step.rawValue) must have a matching VaccineMechanismScenario.")
        }
    }
}

@Suite("VeeMentor.HistoricalContextReflection")
@MainActor
struct HistoricalContextReflectionTests {
    private func mentor() -> VeeMentor {
        let microbe = MicrobeCharacter(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
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

    @Test func fallbackCoversAllScenarios() {
        let m = mentor()
        for scenario in HistoricalContextScenario.allCases {
            let r = m.fallbackHistoricalContextReflection(for: scenario)
            #expect(!r.noticing.isEmpty)
            #expect(!r.kidScientistTakeaway.isEmpty)
        }
    }

    @Test func fallbackAvoidsHeroMythAndMortalityAndWarfareLexicon() {
        // Per CQ CONTENT_STYLE_GUIDE.md § 4.5 anti-credentialism gate + ADR-016:
        // historical figures framed as patient observers — never hero-myth,
        // never mortality framing on disease lexicon, never warfare lexicon.
        let stoplist = [
            // Hero-myth
            "genius", "legendary", "saved millions", "great man", "brilliant",
            // Mortality framing
            "killed", "died", "deadly", "fatal", " death",
            // Warfare
            "fight", "attack", "destroy", " war",
            "enemy", "battle", "weapon", "soldier", "warrior",
            // Shame
            "should ", "must ", "failure",
        ]
        let m = mentor()
        for scenario in HistoricalContextScenario.allCases {
            let r = m.fallbackHistoricalContextReflection(for: scenario)
            let combined = (r.noticing + " " + r.kidScientistTakeaway).lowercased()
            for word in stoplist {
                #expect(!combined.contains(word),
                        "\(scenario) fallback must not surface '\(word.trimmingCharacters(in: .whitespaces))' (anti-credentialism gate).")
            }
        }
    }

    @Test func fallbackUsesHedgingLanguage() {
        let hedges = ["often", "usually", "many", "most", "tends", "may"]
        let m = mentor()
        for scenario in HistoricalContextScenario.allCases {
            let r = m.fallbackHistoricalContextReflection(for: scenario)
            let combined = (r.noticing + " " + r.kidScientistTakeaway).lowercased()
            let hasHedge = hedges.contains { combined.contains($0) }
            #expect(hasHedge,
                    "\(scenario) reflection must use hedging language: \(combined)")
        }
    }

    @Test func fallbackUsesPatientObservationRegister() {
        // Per CQ CONTENT_STYLE_GUIDE.md § 4.5: every figure surfaces as a
        // patient observer doing careful work the kid can also do.
        let registerHints = ["noticing", "careful", "observ", "patient", "small", "quiet"]
        let m = mentor()
        for scenario in HistoricalContextScenario.allCases {
            let r = m.fallbackHistoricalContextReflection(for: scenario)
            let combined = (r.noticing + " " + r.kidScientistTakeaway).lowercased()
            let hits = registerHints.filter { combined.contains($0) }
            #expect(!hits.isEmpty,
                    "\(scenario) reflection should surface at least one patient-observation register cue: \(combined)")
        }
    }

    @Test func scenarioRawValuesAreStable() {
        #expect(HistoricalContextScenario.pasteur.rawValue == "pasteur")
        #expect(HistoricalContextScenario.koch.rawValue == "koch")
        #expect(HistoricalContextScenario.salk.rawValue == "salk")
        #expect(HistoricalContextScenario.marshall.rawValue == "marshall")
        #expect(HistoricalContextScenario.allCases.count == 4)
    }

    @Test func scenarioPairsOneToOneWithHistoricalContextFigure() {
        #expect(HistoricalContextScenario.allCases.count == HistoricalContextFigure.allCases.count)
        for figure in HistoricalContextFigure.allCases {
            #expect(HistoricalContextScenario(rawValue: figure.rawValue) != nil,
                    "Historical figure \(figure.rawValue) must have a matching HistoricalContextScenario.")
        }
    }
}
