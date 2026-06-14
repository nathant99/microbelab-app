import Foundation
import Testing
@testable import Models

@Suite("ImmuneMode")
struct ImmuneModeTests {
    @Test func allCasesAreStable() {
        // Raw values are load-bearing for Codable / persistence / analytics
        // tagging. Don't reorder or rename without a migration plan.
        #expect(ImmuneMode.allCases.count == 2)
        #expect(ImmuneMode.innate.rawValue == "innate")
        #expect(ImmuneMode.adaptive.rawValue == "adaptive")
    }

    @Test func displayNamesAreWarmRegister() {
        #expect(ImmuneMode.innate.displayName == "Macrophage patrol")
        #expect(ImmuneMode.adaptive.displayName == "B-cell library")
    }

    @Test func taglinesFrameTheBodyAsHelping() {
        for mode in ImmuneMode.allCases {
            let tagline = mode.tagline
            #expect(!tagline.isEmpty)
            #expect(tagline.first?.isUppercase ?? false)
        }
    }

    @Test func systemImagesAreValidSFSymbolPrefixes() {
        // Soft check: SF Symbol names are kebab-case alphanumerics with
        // an optional dot separator. We can't validate against the live
        // catalog in unit tests, but ensure no spaces / typos surface.
        for mode in ImmuneMode.allCases {
            let symbol = mode.systemImage
            #expect(!symbol.contains(" "))
            #expect(!symbol.isEmpty)
        }
    }

    /// Trauma-informed register stoplist — the mode picker's copy is the
    /// first surface the kid sees on the defense tab; if any token from
    /// the warfare lexicon leaks here, it sets a punitive register before
    /// the gameplay loop even begins. Mirrors the stoplist authored in
    /// `BCellAntibodyMatchScene` + `AdaptiveImmuneScenario` per
    /// `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed Design Posture.
    @Test(arguments: [
        "fight", "attack", "destroy", "kill",
        "war", "enemy", "battle", "weapon",
        "soldier", "warrior"
    ])
    func displayCopyAvoidsWarfareLexicon(token: String) {
        for mode in ImmuneMode.allCases {
            let composite = "\(mode.displayName) \(mode.tagline)".lowercased()
            #expect(
                !composite.contains(token),
                "Mode \(mode) copy must not contain '\(token)'"
            )
        }
    }

    @Test func codableRoundtripPreservesRawValue() throws {
        for mode in ImmuneMode.allCases {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(ImmuneMode.self, from: data)
            #expect(decoded == mode)
        }
    }
}
