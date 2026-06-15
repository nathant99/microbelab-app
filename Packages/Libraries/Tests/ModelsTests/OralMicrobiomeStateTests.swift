import Foundation
import Testing
@testable import Models

@Suite("OralMicrobiomeState")
nonisolated struct OralMicrobiomeStateTests {
    @Test func emptyStateIsInOralCavitySlot() {
        let state = OralMicrobiomeState.empty
        #expect(state.underlying.activeSlot == .oralCavity)
        #expect(state.sugarLoad == .water)
        #expect(state.tickCount == 0)
        #expect(state.totalPopulation == 0)
    }

    @Test func sugarLoadCanonicalFeedingModeMapping() {
        // Per OralMicrobiomeState doc-comment + the trauma-informed posture
        // table. brushing → .none mirrors "the community settles" register;
        // sugar snack → .sugar tilts toward acid-makers; water/fruit hold
        // the balanced ecology.
        #expect(OralSugarLoad.water.feedingMode == .balanced)
        #expect(OralSugarLoad.fruit.feedingMode == .balanced)
        #expect(OralSugarLoad.sugarSnack.feedingMode == .sugar)
        #expect(OralSugarLoad.brush.feedingMode == .none)
    }

    @Test func sugarLoadRawValueStability() {
        // Load-bearing for analytics (`modeSlug: load.rawValue`) +
        // future Codable persistence. Pin every case so renames surface.
        #expect(OralSugarLoad.water.rawValue == "water")
        #expect(OralSugarLoad.fruit.rawValue == "fruit")
        #expect(OralSugarLoad.sugarSnack.rawValue == "sugarSnack")
        #expect(OralSugarLoad.brush.rawValue == "brush")
    }

    @Test func sugarLoadDisplayNameTraumaSafeRegister() {
        // Display labels surface in the Picker + accessibility value. Trauma-
        // informed: no warnings / no shaming language; "Brush" is care, not
        // an imperative.
        let labels = OralSugarLoad.allCases.map(\.displayName)
        for label in labels {
            #expect(!label.isEmpty)
            let lower = label.lowercased()
            #expect(!lower.contains("should"))
            #expect(!lower.contains("must"))
            #expect(!lower.contains("careless"))
            #expect(!lower.contains("dirty"))
        }
    }

    @Test func sugarLoadAllCasesCoversFourLoads() {
        // Future-proofs against accidental case-additions that the picker UI
        // wouldn't reflect without a corresponding View update.
        #expect(OralSugarLoad.allCases.count == 4)
        let slugs = Set(OralSugarLoad.allCases.map(\.rawValue))
        #expect(slugs == ["water", "fruit", "sugarSnack", "brush"])
    }

    @Test func sugarLoadSystemImagesAreNonEmpty() {
        // SF-Symbol mapping for the segmented picker. Empty strings would
        // silently render a blank tag — guard against future regressions.
        for load in OralSugarLoad.allCases {
            #expect(!load.systemImage.isEmpty,
                    "Sugar load \(load.rawValue) is missing an SF Symbol")
        }
    }

    @Test func codableRoundtripPreservesStateAndSugarLoad() throws {
        let original = OralMicrobiomeState(
            underlying: .empty(in: .oralCavity),
            sugarLoad: .sugarSnack
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OralMicrobiomeState.self, from: data)
        #expect(decoded == original)
    }
}
