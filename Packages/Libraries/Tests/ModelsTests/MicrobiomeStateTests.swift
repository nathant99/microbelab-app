import Foundation
import Testing
@testable import Models

@Suite("MicrobiomeState")
nonisolated struct MicrobiomeStateTests {
    @Test func emptyStartsAtZeroTicks() {
        let state = MicrobiomeState.empty()
        #expect(state.tickCount == 0)
        #expect(state.totalPopulation == 0)
        #expect(state.feedingMode == .balanced)
        #expect(state.antibioticState == .none)
    }

    @Test func totalPopulationSumsAcrossMicrobes() {
        let a = UUID()
        let b = UUID()
        let state = MicrobiomeState(
            populations: [a: 30, b: 12],
            feedingMode: .fiber,
            antibioticState: .none,
            tickCount: 4,
            activeSlot: .colon
        )
        #expect(state.totalPopulation == 42)
    }

    @Test func antibioticStateClassification() {
        #expect(AntibioticState.none.isPerturbing == false)
        #expect(AntibioticState.active(daysLeft: 2).isPerturbing == true)
        #expect(AntibioticState.recovering(ticksLeft: 5).isPerturbing == true)
    }

    @Test func codableRoundTrip() throws {
        let id = UUID()
        let original = MicrobiomeState(
            populations: [id: 88],
            feedingMode: .sugar,
            antibioticState: .recovering(ticksLeft: 6),
            tickCount: 10,
            activeSlot: .smallIntestine
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MicrobiomeState.self, from: data)
        #expect(decoded == original)
    }
}
