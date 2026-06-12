import Foundation
import Testing
@testable import GameEngine
@testable import Models

@Suite("MicrobiomeSimulator")
nonisolated struct MicrobiomeSimulatorTests {
    private func fixtureMicrobes() -> [MicrobeCharacter] {
        [
            MicrobeCharacter(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                slug: "lacto",
                displayName: "Lacto",
                kingdom: .bacteria,
                role: .beneficial,
                preferredEnvironment: .colon,
                growthRate: GrowthRate(onFiber: 0.6, onSugar: 0.1, onBalanced: 0.4, onNone: -0.1),
                catchphrase: "Friend in your food. Friend in your gut.",
                factCard: "Lactobacillus.",
                firstKit: 1
            ),
            MicrobeCharacter(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                slug: "yeast",
                displayName: "Yeast",
                kingdom: .fungi,
                role: .beneficial,
                preferredEnvironment: .smallIntestine,
                growthRate: GrowthRate(onFiber: 0.1, onSugar: 0.7, onBalanced: 0.3, onNone: -0.2),
                catchphrase: "I make air inside bread.",
                factCard: "Saccharomyces.",
                firstKit: 2
            ),
        ]
    }

    @Test func fiberFeedingGrowsLacto() {
        let microbes = fixtureMicrobes()
        let simulator = MicrobiomeSimulator(microbes: microbes)
        let lactoID = microbes[0].id
        let initial = MicrobiomeState(
            populations: [lactoID: 100],
            feedingMode: .fiber,
            antibioticState: .none,
            tickCount: 0,
            activeSlot: .colon
        )
        let next = simulator.tick(initial)
        let nextLacto = next.populations[lactoID] ?? 0
        #expect(nextLacto > 100, "Lacto grows on fiber (got \(nextLacto))")
        #expect(next.tickCount == 1)
    }

    @Test func antibioticShockCollapsesPopulations() {
        let microbes = fixtureMicrobes()
        let simulator = MicrobiomeSimulator(microbes: microbes)
        let lactoID = microbes[0].id
        let initial = MicrobiomeState(
            populations: [lactoID: 1_000],
            feedingMode: .balanced,
            antibioticState: .active(daysLeft: 3),
            tickCount: 0,
            activeSlot: .colon
        )
        let next = simulator.tick(initial)
        let nextLacto = next.populations[lactoID] ?? 0
        #expect(nextLacto < 1_000, "Antibiotic shock must collapse populations")
    }

    @Test func antibioticActiveTransitionsToRecovering() {
        let microbes = fixtureMicrobes()
        let simulator = MicrobiomeSimulator(microbes: microbes)
        let initial = MicrobiomeState(
            populations: [:],
            feedingMode: .balanced,
            antibioticState: .active(daysLeft: 1),
            tickCount: 0,
            activeSlot: .colon
        )
        let next = simulator.tick(initial)
        if case .recovering = next.antibioticState {
            // success
        } else {
            Issue.record("Expected recovering state, got \(next.antibioticState)")
        }
    }

    @Test func determinism100Ticks() {
        // Per FEATURE_PLAN exit criteria: simulator must be stable across 100 ticks.
        let microbes = fixtureMicrobes()
        let simulator = MicrobiomeSimulator(microbes: microbes)
        let initial = MicrobiomeState(
            populations: [microbes[0].id: 50, microbes[1].id: 50],
            feedingMode: .balanced,
            antibioticState: .none,
            tickCount: 0,
            activeSlot: .colon
        )
        var stateA = initial
        var stateB = initial
        for _ in 0..<100 {
            stateA = simulator.tick(stateA)
            stateB = simulator.tick(stateB)
        }
        #expect(stateA == stateB, "Same input sequence must produce same output")
        #expect(stateA.tickCount == 100)
    }
}
