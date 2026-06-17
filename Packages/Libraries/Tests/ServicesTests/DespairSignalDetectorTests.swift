import Foundation
import Testing
@testable import Services

@Suite("DespairSignalDetector")
struct DespairSignalDetectorTests {
    @Test func calmTextReturnsCalm() {
        let detector = DespairSignalDetector()
        let inputs = [
            "I learned about Lacto today",
            "The microbiome is cool",
            "This is hard but I'll keep trying",
            "I want to see more microbes",
        ]
        for text in inputs {
            #expect(detector.detect(in: text) == .calm, "calm text \(text) misclassified")
        }
    }

    @Test func emptyTextReturnsCalm() {
        let detector = DespairSignalDetector()
        #expect(detector.detect(in: "") == .calm)
        #expect(detector.detect(in: "   ") == .calm)
    }

    @Test(arguments: [
        "I want to die",
        "i want to die",
        "I WANT TO DIE",
        "I wish I was dead",
        "i wish i were dead",
        "I'm going to kill myself",
        "i want to end my life",
        "no reason to live",
        "I can't go on",
        "i cant go on anymore",
        "everyone would be better off without me",
        "i don't want to be here anymore",
        "nothing matters anymore",
        "I want to hurt myself",
    ])
    func crisisPhrasesTripCrisisTier(input: String) {
        let detector = DespairSignalDetector()
        #expect(
            detector.detect(in: input) == .elevatedCrisis,
            "crisis input '\(input)' missed"
        )
    }

    @Test(arguments: [
        "no one cares about me",
        "nobody cares",
        "no one loves me",
        "I'm alone",
        "im alone",
        "I feel alone today",
        "I'm scared",
        "i feel scared and tired",
        "i hate myself",
        "I can't do this",
        "everything is wrong",
        "i feel hopeless",
    ])
    func distressPhrasesTripDistressTier(input: String) {
        let detector = DespairSignalDetector()
        #expect(
            detector.detect(in: input) == .elevatedDistress,
            "distress input '\(input)' missed"
        )
    }

    @Test func crisisWinsOverDistressOnMixedText() {
        // A paragraph that includes both — crisis tier wins so the kid
        // sees the strongest support framing.
        let detector = DespairSignalDetector()
        #expect(
            detector.detect(in: "I'm alone and I want to die") == .elevatedCrisis
        )
    }

    @Test func ordinaryGameLanguageDoesNotTripCrisis() {
        // Defensive against ordinary microbe-game vocabulary. The
        // immune-game pathogens are framed as "rest" / "settle" / "library
        // remembers", not warfare; but kid free-text may include "die" /
        // "kill" in casual contexts. The phrase-level matcher should not
        // trip on these.
        let detector = DespairSignalDetector()
        let inputs = [
            "the pathogens die when the macrophage gets them",
            "I want to play immune defense",
            "this kit is killer fun",
            "I want to be a scientist",
            "I want to learn more",
        ]
        for text in inputs {
            #expect(
                detector.detect(in: text) == .calm,
                "ordinary game text '\(text)' tripped detector"
            )
        }
    }

    @Test func diacriticInsensitiveMatch() {
        // ASCII fold ensures curly-apostrophe + diacritics don't slip past.
        let detector = DespairSignalDetector()
        #expect(detector.detect(in: "i can´t go on") == .elevatedCrisis)
        #expect(detector.detect(in: "I CAN'T GO ON") == .elevatedCrisis)
    }

    @Test func whitespaceCollapseHandlesDoubleSpaces() {
        let detector = DespairSignalDetector()
        #expect(detector.detect(in: "i want  to die") == .elevatedCrisis)
        #expect(detector.detect(in: "i want\tto die") == .elevatedCrisis)
    }

    @Test func presentationForCalmIsNil() {
        #expect(DespairSignalSurface.presentation(for: .calm) == nil)
    }

    @Test func presentationForDistressSurfacesCanonicalResources() throws {
        let presentation = DespairSignalSurface.presentation(for: .elevatedDistress)
        let unwrapped = try #require(presentation)
        // Trauma-informed validate-then-inform header copy.
        #expect(unwrapped.header.contains("heavy"))
        // Hedge names the limit on what the app can carry.
        #expect(unwrapped.hedge.contains("trained to help"))
        // Resources are the portfolio-canonical 3-row set.
        #expect(unwrapped.resources.map(\.id) == ["988", "childhelp", "crisis-text-line"])
    }

    @Test func presentationForCrisisSurfacesCanonicalResources() throws {
        let presentation = DespairSignalSurface.presentation(for: .elevatedCrisis)
        let unwrapped = try #require(presentation)
        // Trauma-informed framing: validate the kid's experience FIRST,
        // then surface the support; never lead with the crisis-line copy.
        #expect(unwrapped.header.contains("matters"))
        // Hedge frames the call/text as low-bar ("you don't have to know
        // what to say").
        #expect(unwrapped.hedge.contains("24/7"))
        #expect(unwrapped.resources.map(\.id) == ["988", "childhelp", "crisis-text-line"])
    }

    @Test func presentationCopyAvoidsAlarmFramingStoplist() throws {
        // SAMHSA TIP 57 validate-then-inform register — the surfaced copy
        // must never use alarm / shame / failure language. Per
        // .claude/rules/trauma-informed-content.md.
        let stoplist = [
            "emergency",
            "danger",
            "should",
            "must",
            "failure",
            "wrong",
            "broken",
            "fix you",
        ]
        for severity in [DespairSignalDetector.Severity.elevatedDistress, .elevatedCrisis] {
            let presentation = try #require(DespairSignalSurface.presentation(for: severity))
            let body = (presentation.header + " " + presentation.hedge).lowercased()
            for token in stoplist {
                #expect(
                    !body.contains(token),
                    "presentation for \(severity) contained alarm-tier token '\(token)'"
                )
            }
        }
    }

    @Test func normalizeDropsCaseAndDiacritics() {
        // Internal helper — pin behavior so future refactors don't drift.
        #expect(DespairSignalDetector.normalize("HéLLo Wörld") == "hello world")
    }
}
