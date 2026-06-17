import Foundation
import Testing
@testable import AIMentor
@testable import Models

@Suite("VeeMentor.GlobalMicrobiomeTourCue")
@MainActor
struct GlobalMicrobiomeTourCueTests {
    private func mentor() -> VeeMentor {
        let microbe = MicrobeCharacter(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
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
        for scenario in GlobalMicrobiomeTourScenario.allCases {
            let cue = m.fallbackGlobalMicrobiomeTourCue(for: scenario)
            #expect(!cue.wonderObservation.isEmpty)
            #expect(!cue.connectionToCast.isEmpty)
        }
    }

    @Test func fallbackAvoidsWarfareAndFearAndDirtLexicon() {
        // Per Docs/TECHNICAL_DESIGN.md § Phase 4 + .claude/rules/distributed-narrative.md
        // § cultural-sensitivity gates: Phase 4 tour cues MUST avoid warfare
        // + fear-induction + "dirt/dead" lexicon. Deep-sea + soil framing
        // is canonical wonder + adaptation pride.
        let stoplist = [
            // Warfare
            "fight", "attack", "destroy", " kill", " war",
            "enemy", "battle", "weapon", "soldier", "warrior",
            // Fear induction
            "scary", "horror", "doom", "panic",
            // Soil-shame anti-pattern (frames soil as a thriving system)
            "dirty", "gross", "dead", " rot", " nasty",
            // Deep-sea-shame anti-pattern (vents are thriving systems)
            "deadly", "danger", " germ",
        ]
        let m = mentor()
        for scenario in GlobalMicrobiomeTourScenario.allCases {
            let cue = m.fallbackGlobalMicrobiomeTourCue(for: scenario)
            let combined = (cue.wonderObservation + " " + cue.connectionToCast).lowercased()
            for word in stoplist {
                #expect(!combined.contains(word),
                        "\(scenario) fallback must not surface '\(word.trimmingCharacters(in: .whitespaces))' (trauma-safe + cultural-respect register).")
            }
        }
    }

    @Test func fallbackUsesHedgingLanguage() {
        // Per .claude/rules/foundationmodels.md + ai-content.md: tour cues
        // use hedging language — wonder-forward but never absolute.
        let hedges = ["often", "usually", "many", "most", "tends", "may"]
        let m = mentor()
        for scenario in GlobalMicrobiomeTourScenario.allCases {
            let cue = m.fallbackGlobalMicrobiomeTourCue(for: scenario)
            let combined = (cue.wonderObservation + " " + cue.connectionToCast).lowercased()
            let hasHedge = hedges.contains { combined.contains($0) }
            #expect(hasHedge,
                    "\(scenario) cue must use hedging language: \(combined)")
        }
    }

    @Test func yellowstoneFallbackCreditsIndigenousTEK() {
        // Per .claude/rules/distributed-narrative.md § cultural-sensitivity
        // gates: Yellowstone surface MUST credit Indigenous TEK. Pinned
        // here so a future copy edit can't silently strip the credit.
        let m = mentor()
        let cue = m.fallbackGlobalMicrobiomeTourCue(for: .yellowstoneHotSpring)
        let combined = (cue.wonderObservation + " " + cue.connectionToCast).lowercased()
        #expect(combined.contains("indigenous"),
                "Yellowstone fallback must credit Indigenous knowledge per cultural-sensitivity gate.")
    }

    @Test func fallbackConnectsBackToFeaturedCast() {
        // Per Models/GlobalMicrobiomeTourStop.featuredMicrobeSlugs the
        // mentor connectionToCast SHOULD name at least one of the canonical
        // featured cast members at each stop so the kid sees the bridge.
        let m = mentor()
        // Yellowstone — Crenarch + Therm
        let yellowstone = m.fallbackGlobalMicrobiomeTourCue(for: .yellowstoneHotSpring)
        let yLower = (yellowstone.wonderObservation + " " + yellowstone.connectionToCast).lowercased()
        #expect(yLower.contains("crenarch") || yLower.contains("therm"))
        // Deep-sea — Crenarch + Baro
        let vent = m.fallbackGlobalMicrobiomeTourCue(for: .deepSeaVent)
        let vLower = (vent.wonderObservation + " " + vent.connectionToCast).lowercased()
        #expect(vLower.contains("crenarch") || vLower.contains("baro"))
        // Gut — Lacto + Akker + Bifido
        let gut = m.fallbackGlobalMicrobiomeTourCue(for: .humanGut)
        let gLower = (gut.wonderObservation + " " + gut.connectionToCast).lowercased()
        #expect(gLower.contains("lacto") || gLower.contains("akker") || gLower.contains("bifido"))
        // Soil — Loam + Nodu + Halo
        let soil = m.fallbackGlobalMicrobiomeTourCue(for: .soilUnderground)
        let sLower = (soil.wonderObservation + " " + soil.connectionToCast).lowercased()
        #expect(sLower.contains("loam") || sLower.contains("nodu") || sLower.contains("halo"))
    }

    @Test func scenarioRawValuesAreStable() {
        // Raw values are load-bearing because the async accessor interpolates
        // them into the LLM prompt + the consumer view maps the Models stop
        // case → mentor scenario via raw value.
        #expect(GlobalMicrobiomeTourScenario.yellowstoneHotSpring.rawValue == "yellowstoneHotSpring")
        #expect(GlobalMicrobiomeTourScenario.deepSeaVent.rawValue == "deepSeaVent")
        #expect(GlobalMicrobiomeTourScenario.humanGut.rawValue == "humanGut")
        #expect(GlobalMicrobiomeTourScenario.soilUnderground.rawValue == "soilUnderground")
        #expect(GlobalMicrobiomeTourScenario.allCases.count == 4)
    }

    @Test func scenarioPairsOneToOneWithGlobalMicrobiomeTourStop() {
        // The 4-case alignment is the load-bearing contract — consumer views
        // map a `GlobalMicrobiomeTourStop` to a `GlobalMicrobiomeTourScenario`
        // 1:1 via the raw value.
        #expect(GlobalMicrobiomeTourScenario.allCases.count == GlobalMicrobiomeTourStop.allCases.count)
        for stop in GlobalMicrobiomeTourStop.allCases {
            #expect(GlobalMicrobiomeTourScenario(rawValue: stop.rawValue) != nil,
                    "Tour stop \(stop.rawValue) must have a matching GlobalMicrobiomeTourScenario.")
        }
    }
}
