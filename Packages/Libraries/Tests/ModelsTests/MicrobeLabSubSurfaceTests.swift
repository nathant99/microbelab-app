import Foundation
import Testing
@testable import Models

@Suite("MicrobeLabSubSurface")
struct MicrobeLabSubSurfaceTests {

    @Test("Raw values are stable slug strings")
    func rawValuesAreStable() {
        // Stable slug values matter — App Intents and analytics carry
        // them across launches. Renaming would silently drop existing
        // Shortcut wirings.
        #expect(MicrobeLabSubSurface.diseaseStories.rawValue == "diseaseStories")
        #expect(MicrobeLabSubSurface.vaccineExplainer.rawValue == "vaccineExplainer")
        #expect(MicrobeLabSubSurface.historicalContext.rawValue == "historicalContext")
        #expect(MicrobeLabSubSurface.globalMicrobiomeTour.rawValue == "globalMicrobiomeTour")
        #expect(MicrobeLabSubSurface.allCases.count == 4)
    }

    @Test("All canonical sub-surfaces route to the Microbiome host tab")
    func allHostTabsAreMicrobiome() {
        // Load-bearing: the per-surface `hostTab` property tells the
        // routing layer which tab to surface BEFORE the inner navigation
        // push. Currently all 4 canonical Phase 3 / Phase 4 surfaces live
        // behind the Microbiome tab; future sub-surfaces in other tabs
        // would update this expectation.
        for surface in MicrobeLabSubSurface.allCases {
            #expect(surface.hostTab == .microbiome,
                    "\(surface) is expected to route to the Microbiome tab; if a future surface routes elsewhere, update this test alongside it.")
        }
    }

    @Test("Display titles are kid-readable + non-empty")
    func displayTitlesAreKidReadable() {
        for surface in MicrobeLabSubSurface.allCases {
            #expect(!surface.displayTitle.isEmpty)
            // Titles must not surface internal slugs (the kid sees the
            // display title via the Siri phrase that App Intents render).
            #expect(!surface.displayTitle.contains(surface.rawValue),
                    "\(surface) display title should not leak the raw slug: '\(surface.displayTitle)'")
        }
    }

    @Test("Codable roundtrip preserves the case")
    func codableRoundtrip() throws {
        for surface in MicrobeLabSubSurface.allCases {
            let data = try JSONEncoder().encode(surface)
            let decoded = try JSONDecoder().decode(MicrobeLabSubSurface.self, from: data)
            #expect(decoded == surface)
        }
    }

    @Test("Each canonical case has a unique raw value")
    func rawValuesAreUnique() {
        let rawValues = MicrobeLabSubSurface.allCases.map(\.rawValue)
        let uniqueRawValues = Set(rawValues)
        #expect(rawValues.count == uniqueRawValues.count,
                "MicrobeLabSubSurface raw values must be unique (load-bearing for App Intents wiring).")
    }
}
